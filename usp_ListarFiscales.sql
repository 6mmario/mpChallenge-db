--------------------------------------------------------------------------------
-- Procedimiento: usp_ListarFiscales
-- Descripción: Devuelve todos los registros de la tabla dbo.Fiscal
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_ListarFiscales', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ListarFiscales;
GO

CREATE PROCEDURE dbo.usp_ListarFiscales
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FiscalID,
        Nombre,
        CorreoElectronico,
        Usuario,
        Rol,
        FiscaliaID
    FROM dbo.Fiscal
    ORDER BY Nombre;
END
GO