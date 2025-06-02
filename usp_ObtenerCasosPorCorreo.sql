--------------------------------------------------------------------------------
-- Procedimiento: usp_ObtenerCasosPorCorreo
-- Descripción: Devuelve todos los registros de la tabla dbo.Caso asociados
--              al fiscal identificado por su correo electrónico.
-- Parámetros:
--    @CorreoElectronico NVARCHAR(100) → correo del fiscal
-- Devuelve:
--    Todas las columnas de dbo.Caso cuya columna FiscalID coincida con el FiscalID
--    que corresponde al @CorreoElectronico.
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_ObtenerCasosPorCorreo', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ObtenerCasosPorCorreo;
GO

CREATE PROCEDURE dbo.usp_ObtenerCasosPorCorreo
    @CorreoElectronico  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    /*
      Seleccionamos los casos que estén asignados al fiscal cuyo correo
      sea igual a @CorreoElectronico. Si no existe ningún fiscal con ese
      correo, el SELECT devolverá un conjunto vacío.
    */
    SELECT
        c.CasoID,
        c.FechaRegistro,
        c.Estado,
        c.Progreso,
        c.Descripcion,
        c.FechaUltimaActualizacion,
        c.FiscalID
    FROM dbo.Caso AS c
    INNER JOIN dbo.Fiscal AS f
        ON c.FiscalID = f.FiscalID
    WHERE f.CorreoElectronico = @CorreoElectronico
    ORDER BY c.FechaRegistro;
END
GO
EXEC dbo.usp_ObtenerCasosPorCorreo
    @CorreoElectronico = N'momorale@mp.gob.gt';
GO