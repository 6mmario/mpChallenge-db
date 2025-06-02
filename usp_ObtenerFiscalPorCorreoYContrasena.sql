--------------------------------------------------------------------------------
-- Procedimiento: usp_ObtenerFiscalPorCorreoYContrasena
-- Descripción: Busca un registro en la tabla dbo.Fiscal que coincida
--              con el correo electrónico y la contraseña proporcionados.
-- Parámetros:
--    @CorreoElectronico NVARCHAR(100)  → correo del fiscal
--    @Contrasena        NVARCHAR(255)  → contraseña (o hash) del fiscal
-- Devuelve:
--    – Si encuentra coincidencia, retorna los campos seleccionados del fiscal.
--    – Si no hay coincidencia, retorna un conjunto vacío.
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_ObtenerFiscalPorCorreoYContrasena', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ObtenerFiscalPorCorreoYContrasena;
GO

--------------------------------------------------------------------------------
-- 2. Creamos el procedimiento almacenado
--------------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_ObtenerFiscalPorCorreoYContrasena
    @CorreoElectronico  NVARCHAR(100),
    @Contrasena         NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    /*
      Este SELECT busca el fiscal que coincide con @CorreoElectronico y @Contrasena.
      Luego, en la columna Permisos, arma una lista separada por comas con todos los
      NombrePermiso que tenga asignados en las tablas Fiscal_Permiso → Permiso.

      - Si no existe coincidencia, no devuelve filas.
      - En producción, la comparación de @Contrasena debería hacerse contra un hash
        (i.e. @Contrasena ya llega hasheado) y en la tabla Fiscal también estaría
        almacenado el hash correspondiente.
    */
    SELECT
        f.FiscalID,
        f.Nombre,
        f.CorreoElectronico,
        f.Usuario,
        f.Rol,
        f.FiscaliaID,
        /* Construimos la lista de permisos como 'CREAR_CASO,ASIGNAR_CASO,VER_INFORMES,…' */
        STUFF(
            (
                SELECT ',' + p.NombrePermiso
                FROM dbo.Fiscal_Permiso fp
                INNER JOIN dbo.Permiso p
                    ON fp.PermisoID = p.PermisoID
                WHERE fp.FiscalID = f.FiscalID
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)')
        , 1, 1, '') AS Permisos
    FROM dbo.Fiscal AS f
    WHERE
        f.CorreoElectronico = @CorreoElectronico
        AND f.Contrasena      = @Contrasena;
END
GO


DECLARE 
    @correo NVARCHAR(100) = N'momorale@mp.gob.gt',
    @pwd    NVARCHAR(255) = N'Abc123!@#';  -- o el hash que corresponda

EXEC dbo.usp_ObtenerFiscalPorCorreoYContrasena
    @CorreoElectronico = @correo,
    @Contrasena        = @pwd;

GO