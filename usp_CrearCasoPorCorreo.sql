--------------------------------------------------------------------------------
-- 1. Si existe el procedimiento anterior, lo eliminamos
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_CrearCasoPorCorreo', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CrearCasoPorCorreo;
GO

--------------------------------------------------------------------------------
-- 2. Creamos el procedimiento almacenado
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_CrearCasoPorCorreo
    @CorreoElectronico      NVARCHAR(100),         -- Correo del fiscal
    @Descripcion            NVARCHAR(MAX),         -- Descripción del caso
    @NuevoCasoID            INT            OUTPUT   -- Salida: el CasoID recién creado
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FiscalID INT;

    -- 1) Buscamos el FiscalID asociado al correo
    SELECT @FiscalID = FiscalID
    FROM dbo.Fiscal
    WHERE CorreoElectronico = @CorreoElectronico;

    IF @FiscalID IS NULL
    BEGIN
        -- Si no existe un fiscal con ese correo, lanzamos un error y salimos
        RAISERROR('No existe un fiscal con el correo %s', 16, 1, @CorreoElectronico);
        RETURN;
    END

    -- 2) Insertamos en dbo.Caso usando DEFAULT para FechaRegistro (se asigna el SYSUTCDATETIME())
    --    y establecemos el Estado, Progreso y FechaUltimaActualizacion (con timestamp actual).
    INSERT INTO dbo.Caso
    (
        Estado,
        Progreso,
        Descripcion,
        FechaUltimaActualizacion,
        FiscalID
    )
    VALUES
    (
        N'PENDIENTE',            -- Estado por defecto
        N'0%',                   -- Progreso inicial
        @Descripcion,            -- Descripción que llega como parámetro
        SYSUTCDATETIME(),        -- Igualamos FechaUltimaActualizacion a la fecha actual
        @FiscalID
    );

    -- 3) Capturamos el ID que acaba de generarse
    SET @NuevoCasoID = SCOPE_IDENTITY();
END
GO