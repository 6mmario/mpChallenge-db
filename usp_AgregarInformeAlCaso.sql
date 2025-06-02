--------------------------------------------------------------------------------
-- Procedimiento: usp_AgregarInformeAlCaso
-- Descripción: Valida que el fiscal identificado por @CorreoElectronico 
--              sea el asignado al caso (@CasoID) y, si es así:
--                1) Inserta un nuevo registro en dbo.Informe.
--                2) Asocia ese informe al caso en dbo.Informe_Caso.
--                3) Actualiza Estado, Progreso y FechaUltimaActualizacion en dbo.Caso.
-- Parámetros:
--    @CorreoElectronico   NVARCHAR(100)      → correo del fiscal que desea agregar el informe
--    @CasoID              INT                → ID del caso al que se agrega el informe
--    @TipoInforme         NVARCHAR(100)      → Tipo o título del informe
--    @DescripcionBreve    NVARCHAR(255)      → Descripción breve del informe
--    @Estado              NVARCHAR(50)       → Nuevo estado del caso (p.ej. 'EN_PROGRESO', 'CERRADO')
--    @Progreso            NVARCHAR(50)       → Nuevo progreso del caso (p.ej. '50%', '100%')
--    @NuevoInformeID      INT           OUTPUT → ID del informe recién creado
-- Comportamiento:
--    1) Verifica que exista un fiscal con @CorreoElectronico.
--    2) Verifica que exista el caso con @CasoID.
--    3) Verifica que ese fiscal sea el asignado al caso.
--    4) Si todas las validaciones pasan:
--        a) Inserta en dbo.Informe (FechaGeneracion = SYSUTCDATETIME()).
--        b) Captura el InformeID generado en @NuevoInformeID.
--        c) Inserta en dbo.Informe_Caso (InformeID, CasoID).
--        d) Actualiza dbo.Caso.Estado = @Estado,
--           dbo.Caso.Progreso = @Progreso,
--           dbo.Caso.FechaUltimaActualizacion = SYSUTCDATETIME() para @CasoID.
--    5) Si alguna validación falla, arroja error y no realiza inserciones.
--------------------------------------------------------------------------------

IF OBJECT_ID(N'dbo.usp_AgregarInformeAlCaso', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_AgregarInformeAlCaso;
GO

CREATE PROCEDURE dbo.usp_AgregarInformeAlCaso
    @CorreoElectronico    NVARCHAR(100),
    @CasoID               INT,
    @TipoInforme          NVARCHAR(100),
    @DescripcionBreve     NVARCHAR(255),
    @Estado               NVARCHAR(50),
    @Progreso             NVARCHAR(50),
    @NuevoInformeID       INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @FiscalID    INT,
        @CasoFiscal  INT,
        @ExisteFiscal BIT = 0,
        @ExisteCaso   BIT = 0;

    ---------------------------------------------------------
    -- 1) Verificar que exista un fiscal con @CorreoElectronico
    ---------------------------------------------------------
    SELECT 
        @FiscalID = FiscalID,
        @ExisteFiscal = 1
    FROM dbo.Fiscal
    WHERE CorreoElectronico = @CorreoElectronico;

    IF @ExisteFiscal = 0
    BEGIN
        RAISERROR('No existe ningún fiscal con correo = %s.', 16, 1, @CorreoElectronico);
        RETURN;
    END

    ---------------------------------------------------
    -- 2) Verificar que exista el caso con @CasoID
    ---------------------------------------------------
    SELECT 
        @CasoFiscal = FiscalID,
        @ExisteCaso = 1
    FROM dbo.Caso
    WHERE CasoID = @CasoID;

    IF @ExisteCaso = 0
    BEGIN
        RAISERROR('No existe ningún caso con CasoID = %d.', 16, 1, @CasoID);
        RETURN;
    END

    -------------------------------------------------------------
    -- 3) Validar que el fiscal que llama sea el asignado al caso
    -------------------------------------------------------------
    IF @CasoFiscal <> @FiscalID
    BEGIN
        RAISERROR(
            'El fiscal con correo %s no está autorizado para agregar informe al caso %d.',
            16, 1,
            @CorreoElectronico, @CasoID
        );
        RETURN;
    END

    ---------------------------------------------------
    -- 4a) Insertar en dbo.Informe
    ---------------------------------------------------
    INSERT INTO dbo.Informe
    (
        FechaGeneracion,    -- usa SYSUTCDATETIME()
        TipoInforme,
        DescripcionBreve
    )
    VALUES
    (
        SYSUTCDATETIME(), 
        @TipoInforme,
        @DescripcionBreve
    );

    -- Capturar el ID generado para el informe
    SET @NuevoInformeID = SCOPE_IDENTITY();

    ---------------------------------------------------
    -- 4b) Insertar en dbo.Informe_Caso (N:M)
    ---------------------------------------------------
    INSERT INTO dbo.Informe_Caso
    (
        InformeID,
        CasoID
    )
    VALUES
    (
        @NuevoInformeID,
        @CasoID
    );

    ---------------------------------------------------
    -- 4c) Actualizar Estado, Progreso y FechaUltimaActualizacion en dbo.Caso
    ---------------------------------------------------
    UPDATE dbo.Caso
    SET 
        Estado                   = @Estado,
        Progreso                 = @Progreso,
        FechaUltimaActualizacion = SYSUTCDATETIME()
    WHERE CasoID = @CasoID;
END
GO