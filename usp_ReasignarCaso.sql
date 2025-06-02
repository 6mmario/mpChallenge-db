--------------------------------------------------------------------------------
-- Procedimiento: usp_ReasignarCaso
-- Descripción:
--    Intenta reasignar un caso a un nuevo fiscal. 
--    Si falla alguna validación (caso inexistente, fiscal inexistente, estado ≠ 'PENDIENTE'
--    o fiscalías diferentes), inserta un registro en dbo.LogReasignacionFallida y
--    retorna el motivo del fallo a través del parámetro de salida @MotivoSalida.
--    Si la reasignación es exitosa, actualiza dbo.Caso.FiscalID y FechaUltimaActualizacion,
--    y @MotivoSalida queda NULL.
--
-- Parámetros:
--    @CasoID          INT               → ID del caso que se desea reasignar
--    @NuevoFiscalID   INT               → ID del fiscal al que se quiere reasignar el caso
--    @MotivoSalida    NVARCHAR(255) OUT → Si falla, contiene el motivo; si tiene éxito, queda NULL
--
-- Comportamiento:
--    1) Verificar que exista el caso con @CasoID. Si no existe:
--         • Inserta en LogReasignacionFallida con motivo 'No existe caso'.
--         • @MotivoSalida = 'No existe ningún caso con CasoID = …'
--         • RETURN.
--    2) Verificar que exista el fiscal con @NuevoFiscalID. Si no existe:
--         • Inserta en LogReasignacionFallida con motivo 'No existe fiscal'.
--         • @MotivoSalida = 'No existe ningún fiscal con FiscalID = …'
--         • RETURN.
--    3) Obtener Estado y FiscalActual del caso.
--    4) Si Estado ≠ 'PENDIENTE':
--         • Inserta en LogReasignacionFallida con motivo 'El caso no está en estado PENDIENTE'
--         • @MotivoSalida = 'El caso no está en estado PENDIENTE'
--         • RETURN.
--    5) Obtener FiscaliaID del fiscal actual y del @NuevoFiscalID.
--       Si no coinciden:
--         • Inserta en LogReasignacionFallida con motivo 'El nuevo fiscal no pertenece a la misma fiscalía'
--         • @MotivoSalida = 'El nuevo fiscal no pertenece a la misma fiscalía'
--         • RETURN.
--    6) Si pasa todas las validaciones:
--         • Actualiza dbo.Caso.FiscalID = @NuevoFiscalID y FechaUltimaActualizacion = SYSUTCDATETIME()
--         • @MotivoSalida = NULL
--------------------------------------------------------------------------------

IF OBJECT_ID(N'dbo.usp_ReasignarCaso', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ReasignarCaso;
GO

CREATE PROCEDURE dbo.usp_ReasignarCaso
    @CasoID         INT,
    @NuevoFiscalID  INT,
    @MotivoSalida   NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @Estado            NVARCHAR(50),
        @FiscalActual      INT,
        @FiscaliaActual    INT,
        @FiscaliaNuevo     INT;

    --------------------------------------------------------------------------------
    -- 1) Verificar que exista el caso y obtener Estado y FiscalID actual
    --------------------------------------------------------------------------------
    SELECT
        @Estado = c.Estado,
        @FiscalActual = c.FiscalID
    FROM dbo.Caso AS c
    WHERE c.CasoID = @CasoID;

    IF @FiscalActual IS NULL
    BEGIN
        -- Inserta log de intento fallido
        INSERT INTO dbo.LogReasignacionFallida
        (
            Motivo,
            CasoID,
            FiscalAnteriorID,
            FiscalNuevoID
        )
        VALUES
        (
            N'No existe ningún caso con CasoID = ' + CAST(@CasoID AS NVARCHAR(10)),
            @CasoID,
            NULL,
            @NuevoFiscalID
        );

        SET @MotivoSalida = N'No existe ningún caso con CasoID = ' + CAST(@CasoID AS NVARCHAR(10));
        RETURN;
    END

    --------------------------------------------------------------------------------
    -- 2) Verificar que exista el nuevo fiscal y obtener su FiscaliaID
    --------------------------------------------------------------------------------
    SELECT
        @FiscaliaNuevo = f.FiscaliaID
    FROM dbo.Fiscal AS f
    WHERE f.FiscalID = @NuevoFiscalID;

    IF @FiscaliaNuevo IS NULL
    BEGIN
        -- Inserta log de intento fallido
        INSERT INTO dbo.LogReasignacionFallida
        (
            Motivo,
            CasoID,
            FiscalAnteriorID,
            FiscalNuevoID
        )
        VALUES
        (
            N'No existe ningún fiscal con FiscalID = ' + CAST(@NuevoFiscalID AS NVARCHAR(10)),
            @CasoID,
            @FiscalActual,
            @NuevoFiscalID
        );

        SET @MotivoSalida = N'No existe ningún fiscal con FiscalID = ' + CAST(@NuevoFiscalID AS NVARCHAR(10));
        RETURN;
    END

    --------------------------------------------------------------------------------
    -- 3) Verificar que el caso esté en estado 'PENDIENTE'
    --------------------------------------------------------------------------------
    IF @Estado <> N'PENDIENTE'
    BEGIN
        INSERT INTO dbo.LogReasignacionFallida
        (
            Motivo,
            CasoID,
            FiscalAnteriorID,
            FiscalNuevoID
        )
        VALUES
        (
            N'El caso no está en estado PENDIENTE',
            @CasoID,
            @FiscalActual,
            @NuevoFiscalID
        );

        SET @MotivoSalida = N'El caso no está en estado PENDIENTE';
        RETURN;
    END

    --------------------------------------------------------------------------------
    -- 4) Obtener la FiscaliaID del fiscal actual del caso
    --------------------------------------------------------------------------------
    SELECT
        @FiscaliaActual = f2.FiscaliaID
    FROM dbo.Fiscal AS f2
    WHERE f2.FiscalID = @FiscalActual;

    --------------------------------------------------------------------------------
    -- 5) Verificar que el nuevo fiscal pertenezca a la misma fiscalía
    --------------------------------------------------------------------------------
    IF @FiscaliaActual <> @FiscaliaNuevo
    BEGIN
        INSERT INTO dbo.LogReasignacionFallida
        (
            Motivo,
            CasoID,
            FiscalAnteriorID,
            FiscalNuevoID
        )
        VALUES
        (
            N'El nuevo fiscal no pertenece a la misma fiscalía',
            @CasoID,
            @FiscalActual,
            @NuevoFiscalID
        );

        SET @MotivoSalida = N'El nuevo fiscal no pertenece a la misma fiscalía';
        RETURN;
    END

    --------------------------------------------------------------------------------
    -- 6) Reasignar el caso y actualizar FechaUltimaActualizacion
    --------------------------------------------------------------------------------
    UPDATE dbo.Caso
    SET
        FiscalID = @NuevoFiscalID,
        FechaUltimaActualizacion = SYSUTCDATETIME()
    WHERE
        CasoID = @CasoID;

    -- Si llegamos aquí, la reasignación fue exitosa
    SET @MotivoSalida = NULL;
END
GO