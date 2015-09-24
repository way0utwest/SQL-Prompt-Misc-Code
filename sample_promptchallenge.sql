CREATE PROCEDURE spGetCorporateSalesBySalesman
    @begindate DATE = NULL
  , @salespersonid INT = NULL
AS
    BEGIN
        SET NOCOUNT ON;


        DECLARE @error VARCHAR(2000);

        IF @begindate IS NULL
            SET @begindate = DATEADD(MONTH ,-3 ,GETDATE());

        OPEN SYMMETRIC KEY CorpSalesSymKey
  DECRYPTION BY CERTIFICATE SalesCert WITH PASSWORD = 'UseStr0ngP%ssw7rdsAl#a5ys';

        IF @salespersonid IS NOT NULL
            SELECT  sh.SalesOrderId
                  , sh.OrderDate
                  , sh.duedate
                  , sh.shipdate
                  , CASE WHEN sh.statusid IS NULL THEN 'Unknown'
                         ELSE sh.statusid
                    END
                  , sh.OnlineOrder
                  , sh.PurchaseOrderNumber
                  , sh.CustomerID
                  , 'SalesPerson' = sp.SalesPersonFirstName + ' '
                    + sp.SalesPersonLastName
                  , sh.BilltoAddressID
                  , sh.ShiptoAddressID
                  , sh.ShippingMethodID
                  , sh.totaldue
                  , sd.SalesOrderDetailID
                  , sd.OrderQuantity
                  , dbo.Products.ProductName
                  , 'Line Total Calc' = sd.UnitPrice - ( sd.UnitPrice
                                                         * CAST(CAST(DECRYPTBYKEY(sd.DiscountPercent) AS VARCHAR(10)) AS NUMERIC(4 ,
                                                              2)) )
                  , sd.LineTotal
                  , 'Line Item Alert' = CASE WHEN sd.LineTotal != ( sd.UnitPrice
                                                              - ( sd.UnitPrice
                                                              * CAST(CAST(DECRYPTBYKEY(sd.DiscountPercent) AS VARCHAR(10)) AS NUMERIC(4 ,
                                                              2)) ) )
                                             THEN 'Incorrect Line Item Totals'
                                             ELSE ''
                                        END
                  , ProductName
                  , 'Product Status' = CASE WHEN Products.active = 0
                                            THEN 'Inactive Product'
                                            ELSE ''
                                       END
            FROM    dbo.SalesHeader sh
                    INNER JOIN SalesOrderDetail sd ON sd.SalesOrderID = sh.SalesOrderId
                    INNER JOIN dbo.Products ON Products.ProductID = sd.ProductID
                    INNER JOIN dbo.SalesPerson sp ON sp.SalesPersonID = sh.SalesPersonID;
        ELSE
            SELECT  Error = 'You must enter a salesperson ID';

        CLOSE ALL SYMMETRIC KEYS;

    END;

