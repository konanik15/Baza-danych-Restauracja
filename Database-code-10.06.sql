/****** Object:  Database [pdb-projekt]    Script Date: 10/06/2021 23:06:07 ******/
CREATE DATABASE [pdb-projekt]  (EDITION = 'Basic', SERVICE_OBJECTIVE = 'Basic', MAXSIZE = 100 MB) WITH CATALOG_COLLATION = SQL_Latin1_General_CP1_CI_AS;
GO
ALTER DATABASE [pdb-projekt] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [pdb-projekt] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [pdb-projekt] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [pdb-projekt] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [pdb-projekt] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [pdb-projekt] SET ARITHABORT OFF 
GO
ALTER DATABASE [pdb-projekt] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [pdb-projekt] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [pdb-projekt] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [pdb-projekt] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [pdb-projekt] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [pdb-projekt] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [pdb-projekt] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [pdb-projekt] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [pdb-projekt] SET ALLOW_SNAPSHOT_ISOLATION ON 
GO
ALTER DATABASE [pdb-projekt] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [pdb-projekt] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [pdb-projekt] SET  MULTI_USER 
GO
ALTER DATABASE [pdb-projekt] SET ENCRYPTION ON
GO
ALTER DATABASE [pdb-projekt] SET QUERY_STORE = ON
GO
ALTER DATABASE [pdb-projekt] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 7), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 10, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/*** The scripts of database scoped configurations in Azure should be executed inside the target database connection. ***/
GO
-- ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 8;
GO
/****** Object:  Schema [schema_test]    Script Date: 10/06/2021 23:06:08 ******/
CREATE SCHEMA [schema_test]
GO
/****** Object:  UserDefinedFunction [dbo].[applyDiscount]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
Applies discount to given amount
type 0 is after 10 orders discount, type 1 is 7day discount 
*/
CREATE FUNCTION [dbo].[applyDiscount] (
    @amount INT,
    @discountType INT
)
RETURNS INT AS

BEGIN
    /* Parameters for discounts */
    DECLARE @R1 INT
    SET @R1 = 0.03
    DECLARE @R2 INT
    SET @R2 = 0.05

    DECLARE @afterDiscount INT

    IF(@discountType = 0) SET @afterDiscount = @R1 * @amount
    ELSE IF(@discountType = 1)  SET @afterDiscount = @R2 * @amount

    RETURN @afterDiscount
END;
GO
/****** Object:  UserDefinedFunction [dbo].[calculateAmountOfIndividualCustomerOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[calculateAmountOfIndividualCustomerOrders] (
    @customer_id INT
	
)
RETURNS INT AS
BEGIN
	--Konfiguracja minimalnej kwoty zamowienia aby liczylo sie do przyznania znizki
	DECLARE @minimalAmount INT
	SET @minimalAmount = 30

    DECLARE @amountOfOrders INT
    SET @amountOfOrders = 
		(
        SELECT COUNT(order_id) FROM [dbo].[getCustomerPaidOrders](@customer_id)
        WHERE [dbo].[callculateOrderCost]([dbo].[getCustomerPaidOrders](@customer_id).order_id) > @minimalAmount
		)

    RETURN @amountOfOrders

	-- SET @monthlyBill = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = (SELECT order_id FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    --     WHERE MONTH(realization_time) = @selectedMonth AND YEAR(realization_time) = @selectedYear AND company_id = @company_id AND company_order = 1 AND status = 0))

END;
GO
/****** Object:  UserDefinedFunction [dbo].[calculateCompanyBalance]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[calculateCompanyBalance] (
    @company_id INT
)
RETURNS INT AS
BEGIN

    DECLARE @unpaidAmount INT
    SET @unpaidAmount = (
        SELECT SUM(cost) AS do_opłacenia
        FROM [dbo].[getCompanyUnpaidOrders](@company_id)
        JOIN order_items ON order_items.order_id = [dbo].[getCompanyUnpaidOrders].order_id)
    RETURN @unpaidAmount

	-- SET @monthlyBill = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = (SELECT order_id FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    --     WHERE MONTH(realization_time) = @selectedMonth AND YEAR(realization_time) = @selectedYear AND company_id = @company_id AND company_order = 1 AND status = 0))

END;
GO
/****** Object:  UserDefinedFunction [dbo].[calculateCustomerBalance]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[calculateCustomerBalance] (
    @customer_id INT
)
RETURNS INT AS
BEGIN

    DECLARE @amount INT
    SET @amount = (
        SELECT SUM(cost) AS do_opłacenia
        FROM [dbo].[getCustomerUnpaidOrders](@customer_id)
        JOIN order_items ON order_items.order_id = [dbo].[getCustomerUnpaidOrders].order_id)
    RETURN @amount

	-- SET @monthlyBill = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = (SELECT order_id FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    --     WHERE MONTH(realization_time) = @selectedMonth AND YEAR(realization_time) = @selectedYear AND company_id = @company_id AND company_order = 1 AND status = 0))

END;
GO
/****** Object:  UserDefinedFunction [dbo].[calculateCustomerExpenses]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[calculateCustomerExpenses] (
    @customer_id INT
)
RETURNS INT AS
BEGIN

    DECLARE @amount INT
    SET @amount = (
        SELECT SUM(cost) AS do_opłacenia
        FROM [dbo].[getCustomerPaidOrders](@customer_id)
        JOIN order_items ON order_items.order_id = [dbo].[getCustomerPaidOrders].order_id)
    RETURN @amount

	-- SET @monthlyBill = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = (SELECT order_id FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    --     WHERE MONTH(realization_time) = @selectedMonth AND YEAR(realization_time) = @selectedYear AND company_id = @company_id AND company_order = 1 AND status = 0))

END;
GO
/****** Object:  UserDefinedFunction [dbo].[calculateMonthlyBill]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[calculateMonthlyBill] (
    @company_id INT,
    @selectedMonth INT,
	@selectedYear INT
)
RETURNS INT AS

BEGIN

    DECLARE @monthlyBill INT

	SET @monthlyBill = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = (SELECT order_id FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
        WHERE MONTH(realization_time) = @selectedMonth AND YEAR(realization_time) = @selectedYear AND company_id = @company_id AND company_order = 1 AND status = 0))

    RETURN @monthlyBill
END;
GO
/****** Object:  UserDefinedFunction [dbo].[callculateAmountOfSeats]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[callculateAmountOfSeats](
	@table_id INT 
)
RETURNS INT
AS
BEGIN
    DECLARE @amountOfSeats INT
    SET @amountOfSeats = (SELECT SUM(seats) FROM dbo.tables)

	
    RETURN @amountOfSeats
END
GO
/****** Object:  UserDefinedFunction [dbo].[callculateOrderCost]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[callculateOrderCost](
    @order_id SMALLINT
)
RETURNS INT
AS
BEGIN
    DECLARE @amount INT
    SET @amount = (SELECT SUM(cost) FROM dbo.order_items WHERE order_id = @order_id)
    RETURN @amount
END
GO
/****** Object:  UserDefinedFunction [dbo].[checkIfSeafoodAreAvailable]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE FUNCTION [dbo].[checkIfSeafoodAreAvailable] (@order_id INT)

RETURNS BIT 
AS

BEGIN

	DECLARE @created datetime
	DECLARE @isSeafoodTime BIT

	SET @created = (SELECT created_at FROM dbo.orders WHERE order_id = @order_id)

	IF DATEPART(dw, @created) = 5 OR DATEPART(dw, @created) = 6 OR DATEPART(dw, @created) = 7
        SET @isSeafoodTime = 1
    ELSE
        SET @isSeafoodTime = 0

	RETURN @isSeafoodTime
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE FUNCTION [dbo].[fn_diagramobjects]() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
	
GO
/****** Object:  Table [dbo].[orders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[orders](
	[order_id] [int] IDENTITY(1,1) NOT NULL,
	[customer_id] [int] NOT NULL,
	[created_at] [smalldatetime] NOT NULL,
	[realization_time] [smalldatetime] NULL,
	[bill_id] [int] NOT NULL,
	[online_order] [bit] NOT NULL,
	[company_order] [bit] NOT NULL,
	[company_id] [int] NULL,
	[takeout] [bit] NOT NULL,
 CONSTRAINT [PK_orders] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[customers]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers](
	[customer_id] [int] IDENTITY(1,1) NOT NULL,
	[first_name] [varchar](50) NOT NULL,
	[second_name] [varchar](50) NULL,
	[email] [varchar](50) NOT NULL,
	[phone] [varchar](16) NOT NULL,
 CONSTRAINT [PK_customers] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_customers] UNIQUE NONCLUSTERED 
(
	[email] ASC,
	[phone] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[bills]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bills](
	[bill_id] [int] IDENTITY(1,1) NOT NULL,
	[discount] [int] NOT NULL,
	[status] [bit] NOT NULL,
	[invoice] [bit] NOT NULL,
 CONSTRAINT [PK_bills] PRIMARY KEY CLUSTERED 
(
	[bill_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[companies]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[companies](
	[company_id] [int] IDENTITY(1,1) NOT NULL,
	[company_name] [varchar](100) NOT NULL,
	[NIP] [varchar](15) NOT NULL,
	[address] [varchar](200) NOT NULL,
	[phone_number] [varchar](50) NOT NULL,
 CONSTRAINT [PK_companies] PRIMARY KEY CLUSTERED 
(
	[company_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_companies] UNIQUE NONCLUSTERED 
(
	[NIP] ASC,
	[phone_number] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[unpaidBills]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[unpaidBills] 
AS
    SELECT 
	customers.first_name AS Imie,
	customers.second_name AS Nazwisko,
	companies.company_name AS Nazwa_Firmy,
	customers.phone AS Numer_Telefonu,
	dbo.callculateOrderCost(orders.order_id) AS Kwota_Zamowienia, -- Wykorzystanie funkcji do obliczenia kwoty zamowienia
	orders.realization_time AS Data_realizacji


    FROM dbo.bills
	JOIN dbo.orders
		ON bills.bill_id = orders.bill_id
	JOIN dbo.customers
		ON customers.customer_id = orders.order_id
	JOIN dbo.companies
		ON companies.company_id = orders.bill_id
    WHERE [status] = 0

GO
/****** Object:  View [dbo].[thisMonthOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[thisMonthOrders] 
AS
    SELECT *
    FROM dbo.orders
    WHERE MONTH(created_at) = MONTH(getdate())
GO
/****** Object:  Table [dbo].[reservations]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[reservations](
	[reservation_id] [int] IDENTITY(1,1) NOT NULL,
	[table_id] [smallint] NOT NULL,
	[startTime] [smalldatetime] NOT NULL,
	[endTime] [smalldatetime] NULL,
	[number_of_people] [smallint] NOT NULL,
	[order_id] [int] NOT NULL,
 CONSTRAINT [PK_reservations222222222] PRIMARY KEY CLUSTERED 
(
	[reservation_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[avaliableTables]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Get avaliable tables today */
CREATE FUNCTION [dbo].[avaliableTables](
    @date DATETIME
)
RETURNS TABLE 
AS
RETURN 
    SELECT -- TODO Niech funkcja przyjmuje date i sprawdzi czy stolik w tej dacie + ~~ 3 h jest wolny - coby nie tworzyc rezerwacji na stolik ktory ma rezerwacje za 10 minut xd 
       *
    FROM dbo.reservations
    WHERE reservations.startTime <= @date AND @date <=reservations.endTime
        
GO
/****** Object:  View [dbo].[currentReservations]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[currentReservations] 
AS
    SELECT 
	customers.first_name,
	customers.second_name,
	orders.order_id,
	reservations.table_id,
	reservations.number_of_people
    FROM dbo.orders
	JOIN dbo.reservations
		ON orders.order_id = reservations.order_id
	JOIN dbo.customers
		ON customers.customer_id = orders.customer_id
    WHERE reservations.startTime >= GETDATE()
GO
/****** Object:  Table [dbo].[menus]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[menus](
	[menu_id] [int] NOT NULL,
	[item_id] [int] NOT NULL,
	[startM] [smalldatetime] NOT NULL,
	[endM] [smalldatetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[items]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[items](
	[item_id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[beverage] [bit] NOT NULL,
	[cost] [float] NOT NULL,
	[seafood] [bit] NOT NULL,
 CONSTRAINT [PK_items] PRIMARY KEY CLUSTERED 
(
	[item_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_items] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[currentMenu]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[currentMenu] 
AS
    SELECT 
	-- menus.menu_id,
	-- menus.startM AS Poczatek_oferty,
	-- menus.endM AS Koniec_Ofery,
	items.name,
	items.cost,
	items.beverage

    FROM menus
	INNER JOIN dbo.items
		ON menus.item_id = items.item_id 
    WHERE  menus.endM >= GETDATE() AND GETDATE() >= menus.startM
GO
/****** Object:  View [dbo].[showIndividualCustomersBills]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW [dbo].[showIndividualCustomersBills] 
AS
    SELECT 
	customers.first_name AS Imie,
	customers.second_name AS Nazwisko,
	orders.bill_id AS Numer_Rachunku,
	dbo.callculateOrderCost(orders.order_id) AS Kwota_Zamowienia, -- Wykorzystanie funkcji do obliczenia kwoty zamowienia
	dbo.bills.status AS StatusPlatnosci


	-- Oblicz rachunek z zamowienia i wstaw do tabeli
    FROM customers
	JOIN dbo.orders
		ON orders.customer_id = customers.customer_id
	
		
    JOIN dbo.bills 
		ON bills.bill_id = orders.bill_id

	WHERE orders.company_order = 0

GO
/****** Object:  Table [dbo].[employees]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[employees](
	[customer_id] [int] NOT NULL,
	[company_id] [int] NOT NULL,
 CONSTRAINT [PK_employees] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC,
	[company_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[showBusinessCustomers]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[showBusinessCustomers] 
AS
    SELECT 
	customers.first_name,
	customers.second_name,
	customers.email,
	customers.phone,
	companies.company_name,
	companies.NIP,
	companies.address,
	companies.phone_number
    FROM dbo.employees
	JOIN dbo.customers
		ON employees.customer_id = customers.customer_id
	JOIN dbo.companies
		ON employees.company_id = companies.company_id
    
GO
/****** Object:  View [dbo].[showIndividualCustomers]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Display all clients that are not company dlients
CREATE VIEW [dbo].[showIndividualCustomers] 
AS
    SELECT 
        dbo.customers.first_name AS Imie,
        dbo.customers.second_name AS Nazwisko,
        dbo.customers.phone AS Numer_telefonu,
		dbo.customers.email AS Email
    FROM dbo.customers
    LEFT JOIN dbo.employees ON dbo.customers.customer_id = dbo.employees.customer_id
    WHERE dbo.employees.company_id IS NULL
GO
/****** Object:  View [dbo].[showBuisnessCustomersBills]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE VIEW [dbo].[showBuisnessCustomersBills] 
AS
    SELECT
	companies.company_name AS Nazwa_firmy,
	customers.first_name AS Imie_Pracownika,
	customers.second_name AS Nazwisko_pracownika,
	orders.bill_id AS Numer_Rachunku,
	dbo.callculateOrderCost(orders.order_id) AS Kwota_Zamowienia, -- Wykorzystanie funkcji do obliczenia kwoty zamowienia
	dbo.bills.status AS StatusPlatnosci


	-- Oblicz rachunek z zamowienia i wstaw do tabeli
    FROM customers
	JOIN dbo.orders
		ON orders.customer_id = customers.customer_id
	JOIN companies
		ON companies.company_id = orders.company_id
    JOIN dbo.bills 
		ON bills.bill_id = orders.bill_id

	WHERE orders.company_order = 1

GO
/****** Object:  View [dbo].[showUnrealizedOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[showUnrealizedOrders] 
AS
    SELECT 
	customers.first_name AS Imie,
	customers.second_name AS Nazwisko,
	companies.company_name AS Nazwa_Firmy,
	customers.phone AS Numer_Telefonu,
	dbo.callculateCost(orders.order_id) AS Kwota_Zamowienia, -- Wykorzystanie funkcji do obliczenia kwoty zamowienia
	orders.realization_time AS Data_realizacji


    FROM dbo.bills
	JOIN dbo.orders
		ON bills.bill_id = orders.bill_id
	JOIN dbo.customers
		ON customers.customer_id = orders.order_id
	JOIN dbo.companies
		ON companies.company_id = orders.bill_id
    WHERE dbo.orders.realization_time = NULL

GO
/****** Object:  UserDefinedFunction [dbo].[getCompanyUnpaidOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getCompanyUnpaidOrders] (
    @company_id INT
)
RETURNS TABLE AS

    RETURN SELECT order_id
    FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    WHERE company_id = @company_id AND status = 0

GO
/****** Object:  View [dbo].[companiesBilance]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[companiesBilance] 
AS
    SELECT 
        companies.company_name,
        dbo.calculateCompanyBalance(companies.company_id) AS Bilans
    FROM companies
GO
/****** Object:  UserDefinedFunction [dbo].[getCustomerUnpaidOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getCustomerUnpaidOrders] (
    @customer_id INT
)
RETURNS TABLE AS

    RETURN SELECT order_id
    FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    WHERE customer_id = @customer_id AND status = 0

GO
/****** Object:  View [dbo].[customersBilance]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[customersBilance] 
AS
    SELECT 
        customers.customer_id,
        dbo.calculateCustomerBalance(customers.customer_id) AS Zadluzenie
	FROM dbo.customers
    LEFT JOIN dbo.employees ON dbo.customers.customer_id = dbo.employees.customer_id
    WHERE dbo.employees.company_id IS NULL
GO
/****** Object:  UserDefinedFunction [dbo].[getCustomerPaidOrders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getCustomerPaidOrders] (
    @customer_id INT
)
RETURNS TABLE AS

    RETURN SELECT order_id
    FROM dbo.orders JOIN dbo.bills ON bills.bill_id = orders.bill_id 
    WHERE 
		customer_id = @customer_id
		AND 
		status = 1
		AND
		orders.company_order = 0

GO
/****** Object:  View [dbo].[customersExpenses]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW [dbo].[customersExpenses] 
AS
    SELECT 
        customers.customer_id,
        dbo.calculateCustomerExpenses(customers.customer_id) AS OplaconeKwotyZamowien
	FROM dbo.customers
    LEFT JOIN dbo.employees ON dbo.customers.customer_id = dbo.employees.customer_id
    WHERE dbo.employees.company_id IS NULL
GO
/****** Object:  Table [dbo].[discountParameters]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[discountParameters](
	[demanded_amount] [smallint] NOT NULL,
	[demanded_cost] [smallint] NOT NULL,
	[permament_discount] [smallint] NOT NULL,
	[single_demanded_cost] [smallint] NOT NULL,
	[one_time_discount] [smallint] NOT NULL,
	[duration_of_one_time_discount] [smallint] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[discounts]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[discounts](
	[customer_id] [int] NOT NULL,
	[start_of_discount] [smalldatetime] NULL,
	[end_of_discount] [smalldatetime] NULL,
 CONSTRAINT [PK_discounts] PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[order_items]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[order_items](
	[order_id] [int] NOT NULL,
	[item_id] [int] NOT NULL,
	[cost] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_principal_name] UNIQUE NONCLUSTERED 
(
	[principal_id] ASC,
	[name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tables]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tables](
	[table_id] [smallint] IDENTITY(1,1) NOT NULL,
	[seats] [smallint] NOT NULL,
 CONSTRAINT [PK_tables] PRIMARY KEY CLUSTERED 
(
	[table_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[takeout_orders]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[takeout_orders](
	[order_id] [int] NOT NULL,
	[pickup_time] [datetime] NOT NULL,
	[pickup_status] [bit] NOT NULL,
 CONSTRAINT [PK_takeout_orders] PRIMARY KEY CLUSTERED 
(
	[order_id] ASC,
	[pickup_time] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_takeout_orders] UNIQUE NONCLUSTERED 
(
	[order_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_customers]    Script Date: 10/06/2021 23:06:08 ******/
CREATE NONCLUSTERED INDEX [IX_customers] ON [dbo].[customers]
(
	[customer_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bills] ADD  CONSTRAINT [DF_bills_discount]  DEFAULT ((0)) FOR [discount]
GO
ALTER TABLE [dbo].[bills] ADD  CONSTRAINT [DF_bills_status]  DEFAULT ((0)) FOR [status]
GO
ALTER TABLE [dbo].[bills] ADD  CONSTRAINT [DF_bills_invoice]  DEFAULT ((0)) FOR [invoice]
GO
ALTER TABLE [dbo].[items] ADD  CONSTRAINT [DF_items_beverage]  DEFAULT ((0)) FOR [beverage]
GO
ALTER TABLE [dbo].[items] ADD  CONSTRAINT [DF_items_cost]  DEFAULT ((0)) FOR [cost]
GO
ALTER TABLE [dbo].[items] ADD  CONSTRAINT [DF_items_seafood]  DEFAULT ((0)) FOR [seafood]
GO
ALTER TABLE [dbo].[order_items] ADD  CONSTRAINT [DF_order_items_cost]  DEFAULT ((0)) FOR [cost]
GO
ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [DF_orders_online_order]  DEFAULT ((0)) FOR [online_order]
GO
ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [DF_orders_company_order]  DEFAULT ((0)) FOR [company_order]
GO
ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [DF_orders_takeout]  DEFAULT ((0)) FOR [takeout]
GO
ALTER TABLE [dbo].[takeout_orders] ADD  CONSTRAINT [DF_takeout_orders_pickup_status]  DEFAULT ((0)) FOR [pickup_status]
GO
ALTER TABLE [dbo].[discounts]  WITH CHECK ADD  CONSTRAINT [FK_discounts_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[discounts] CHECK CONSTRAINT [FK_discounts_customers]
GO
ALTER TABLE [dbo].[employees]  WITH NOCHECK ADD  CONSTRAINT [FK_employees_companies] FOREIGN KEY([company_id])
REFERENCES [dbo].[companies] ([company_id])
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [FK_employees_companies]
GO
ALTER TABLE [dbo].[employees]  WITH NOCHECK ADD  CONSTRAINT [FK_employees_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[employees] CHECK CONSTRAINT [FK_employees_customers]
GO
ALTER TABLE [dbo].[menus]  WITH CHECK ADD  CONSTRAINT [FK_menus_items] FOREIGN KEY([item_id])
REFERENCES [dbo].[items] ([item_id])
GO
ALTER TABLE [dbo].[menus] CHECK CONSTRAINT [FK_menus_items]
GO
ALTER TABLE [dbo].[order_items]  WITH CHECK ADD  CONSTRAINT [FK_order_items_items] FOREIGN KEY([item_id])
REFERENCES [dbo].[items] ([item_id])
GO
ALTER TABLE [dbo].[order_items] CHECK CONSTRAINT [FK_order_items_items]
GO
ALTER TABLE [dbo].[order_items]  WITH CHECK ADD  CONSTRAINT [FK_order_items_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([order_id])
GO
ALTER TABLE [dbo].[order_items] CHECK CONSTRAINT [FK_order_items_orders]
GO
ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_bills] FOREIGN KEY([bill_id])
REFERENCES [dbo].[bills] ([bill_id])
GO
ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_bills]
GO
ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_companies] FOREIGN KEY([company_id])
REFERENCES [dbo].[companies] ([company_id])
GO
ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_companies]
GO
ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_customers] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_customers]
GO
ALTER TABLE [dbo].[reservations]  WITH CHECK ADD  CONSTRAINT [FK_reservations_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([order_id])
GO
ALTER TABLE [dbo].[reservations] CHECK CONSTRAINT [FK_reservations_orders]
GO
ALTER TABLE [dbo].[reservations]  WITH CHECK ADD  CONSTRAINT [FK_reservations_tables] FOREIGN KEY([table_id])
REFERENCES [dbo].[tables] ([table_id])
GO
ALTER TABLE [dbo].[reservations] CHECK CONSTRAINT [FK_reservations_tables]
GO
ALTER TABLE [dbo].[takeout_orders]  WITH CHECK ADD  CONSTRAINT [FK_takeout_orders_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([order_id])
GO
ALTER TABLE [dbo].[takeout_orders] CHECK CONSTRAINT [FK_takeout_orders_orders]
GO
/****** Object:  StoredProcedure [dbo].[addBill]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[addBill](
	@bill_id [int] = NULL OUT,
    @discount [int],
	@status [bit],
	@invoice [bit]
)
AS
BEGIN 
    SET NOCOUNT ON 
   
    --IF @bill_id IS NULL THROW 51000, 'Id cant be null', 1
    --IF @discount IS NULL THROW 51000, 'Discount cant be null', 1
	--IF @status IS NULL THROW 51000, 'Status cant be null', 1
    --IF @invoice IS NULL THROW 51000, 'Invoice cant be null', 1

    INSERT INTO dbo.bills(
        --bill_id,
		discount,
		status,
		invoice
    )
    VALUES ( 
        --@bill_id,
		@discount,
		@status,
		@invoice           
    ) 
	SET @bill_id = SCOPE_IDENTITY()
END
GO
/****** Object:  StoredProcedure [dbo].[addCompany]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[addCompany](
	@company_name [varchar](100),
    @NIP [varchar](15),
	@address [varchar](200),
	@phone_number [varchar](50)
)
AS
BEGIN 
    SET NOCOUNT ON 
   
    IF @company_name IS NULL THROW 51000, 'Pusta nazwa firmy', 1
    IF @NIP IS NULL THROW 51000, 'Niepoprawny NIP', 1
    IF @address IS NULL THROW 51000, 'Pusty adres', 1
    IF @phone_number IS NULL THROW 51000, 'Pusty numer telefonu', 1

    INSERT INTO dbo.companies(
        company_name,
        NIP,
        address,
        phone_number
    )
    VALUES ( 
        @company_name,
        @NIP,
        @address,
        @phone_number                    
    ) 

END
GO
/****** Object:  StoredProcedure [dbo].[addReservation]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[addReservation](
	@reservation_id int = NULL OUT,
	@table_id smallint,
    @customer_id smallint,
	@startTime datetime,
	@number_of_people smallint,
	@order_id int
)
AS
BEGIN 
	IF @table_id IS NULL THROW 51000, 'Podaj table_id', 1
	IF @startTime IS NULL THROW 51000, 'Podaj date rezerwacji', 1
	IF @number_of_people IS NULL OR @number_of_people < 2 THROW 51000, 'Niepoprawna ilość osób', 1 --minimum 2 osoby
	IF @order_id IS NULL THROW 51000, 'Przed utworzeniem rezerwacji stwórz zamówienie', 1

    IF(dbo.callculateOrderCost(@order_id) < 200)
    BEGIN
        IF(dbo.callculateOrderCost(@order_id) < 50 AND dbo.calculateAmountOfIndividualCustomerOrders(@customer_id) < 5)
        THROW 51000, 'Nie spełniasz wymagań na utworzenie rezerwacji', 1
    END

    INSERT INTO [dbo].[reservations]
           ([table_id]
           ,[startTime]
		   ,[endTime]
           ,[number_of_people]
           ,[order_id])
     VALUES
           (@table_id,
            @startTime,
			DATEADD(HOUR, 2, @startTime), -- czas trwania rezerwacji
            @number_of_people, 
            @order_id)
	SET @reservation_id = SCOPE_IDENTITY();

END
GO
/****** Object:  StoredProcedure [dbo].[addTakeoutOrder]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[addTakeoutOrder](
	@order_id [int],
    @pickup_time [datetime]
)
AS
BEGIN 
    SET NOCOUNT ON 
   
    IF @order_id IS NULL THROW 51000, 'Wpisz ID istniejącego zamówienia', 1
    IF @pickup_time IS NULL THROW 51000, 'Wpisz czas odbioru zamówienia', 1

    INSERT INTO dbo.takeout_orders(
        order_id,
        pickup_time,
        pickup_status
    )
    VALUES ( 
        @order_id,
        @pickup_time,
        0            
    ) 

END
GO
/****** Object:  StoredProcedure [dbo].[cancelReservation]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cancelReservation](
	@reservation_id [int]
)
AS
BEGIN 
    IF @reservation_id IS NULL THROW 51000, 'Podaj id rezerwacji', 1
    DELETE FROM dbo.reservations WHERE reservation_id = @reservation_id;
END
GO
/****** Object:  StoredProcedure [dbo].[checkTableAvalibility]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[checkTableAvalibility](
	@table_id [int]
)
AS
BEGIN
    DECLARE @tables INT
    SET @tables = 0
    SELECT @tables = COUNT(*) FROM dbo.availability WHERE table_id = @table_id
    IF @tables > 0 RETURN 1
    ELSE RETURN 0
END
GO
/****** Object:  StoredProcedure [dbo].[editItem]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[editItem](
	@item_id [int],
    @name [varchar](50),
    @beverage [bit],
    @cost [float],
    @seafood [bit]
)
AS
BEGIN 
    SET NOCOUNT ON 
   
    IF @item_id IS NULL THROW 51000, 'Wpisz ID', 1
    UPDATE dbo.items SET
        name = @name,
        beverage = @beverage,
        cost = @cost,
        seafood = @seafood
    WHERE item_id = @item_id

END
GO
/****** Object:  StoredProcedure [dbo].[sp_addCustomer]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      PBD grupa 2
-- Create Date: 
-- Description: Tworzenie klienta
-- =============================================
CREATE PROCEDURE [dbo].[sp_addCustomer]
(
    -- Add the parameters for the stored procedure here
	@customer_id int = NULL OUT,
	@first_name varchar(50),
	@second_name varchar(50),
	@email varchar(50),
	@phone varchar(16)
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION;

	  IF @first_name IS NULL
		THROW 51000, 'first name is null', 1

	  IF @second_name IS NULL
		THROW 51000, 'secondname is null', 1

      IF @email IS NULL
		THROW 51000, 'email is null', 1

      IF @phone IS NULL
		THROW 51000, 'phone is null', 1

	INSERT INTO customers
           (first_name
           ,second_name
           ,email
           ,phone)
     VALUES
           (@first_name
           ,@second_name
           ,@email
           ,@phone)
	SET @customer_id = SCOPE_IDENTITY();

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_addEmployees]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      PBD grupa 2
-- Create Date: 
-- Description: Tworzenie pracownika
-- =============================================
CREATE PROCEDURE [dbo].[sp_addEmployees]
(
    -- Add the parameters for the stored procedure here
	@customer_id int = NULL OUT,
	@company_id int = NULL OUT
	
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION;

	  IF @customer_id IS NULL
		THROW 51000, 'Customer_id is null', 1

	  IF @company_id IS NULL
		THROW 51000, 'Company_id is null', 1

      

	INSERT INTO employees
           (customer_id
           ,company_id
           )
     VALUES
           (@customer_id
           ,@company_id
           )
	

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_addItems]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Name
-- Create Date: 
-- Description: 
-- =============================================
CREATE PROCEDURE [dbo].[sp_addItems]
(
    -- Add the parameters for the stored procedure here
	@item_id [int],
    @name [varchar](50),
    @beverage [bit],
    @cost [float],
    @seafood [bit]
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION;

	  IF @name IS NULL
		THROW 51000, 'first name is null', 1

	  IF @beverage IS NULL OR @beverage < 0 OR @beverage > 1
		THROW 51000, 'invalid logical value', 1

      IF @cost IS NULL OR @cost<=0
		THROW 51000, 'cost is null or <=0', 1

      IF @seafood IS NULL OR @seafood < 0 OR @seafood > 1
		THROW 51000, 'invalid logical value', 1

	INSERT INTO items
           (name
           ,beverage
           ,cost
           ,seafood)
     VALUES
           (@name
           ,@beverage
           ,@cost
           ,@seafood)
	SET @item_id = SCOPE_IDENTITY();

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_addMenu]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Name
-- Create Date: 
-- Description: 
-- =============================================
CREATE PROCEDURE [dbo].[sp_addMenu]
(
    -- Add the parameters for the stored procedure here
	@menu_id [int],
    @item_id [int],
    @startM [smalldatetime],
    @endM [smalldatetime]
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
	BEGIN TRY
	BEGIN TRANSACTION;

	  IF @item_id IS NULL
		THROW 51000, 'item_id is null', 1 

	  IF @startM IS NULL OR @endM IS NULL 
		THROW 51000, 'invalid logical value', 1


	INSERT INTO menus
           (menu_id
		   ,item_id
           ,startM
           ,endM)
     VALUES
           (@menu_id
		   ,@item_id
           ,@startM
           ,@endM)
	

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_addOrder]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- =============================================
-- Author:      PBD grupa 2
-- Create Date: 
-- Description: Tworzenie zamowienia
-- =============================================
CREATE PROCEDURE [dbo].[sp_addOrder]
(
    -- Add the parameters for the stored procedure here
	@order_id int ,
    @customer_id int,
    @created_at smalldatetime,
	@realization_time smalldatetime,
	@online_order bit,
	@company_order bit,
	@bill_id int,
	@company_id int,
	@takeout bit,
	@status bit,
	@invoice bit
)
AS
BEGIN
	
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION;

	DECLARE @amountOfOrdersForDiscount  INT
	Set @amountOfOrdersForDiscount  = 10

	DECLARE @repetitiveDiscount INT 
	Set @repetitiveDiscount  = 3

	IF @customer_id IS NULL 
	THROW 51000, '@No such customer', 1
		-- Or exec addCustomer 

    IF @created_at IS NULL
	THROW 51000, '@created_at is null', 1

    IF @bill_id IS NULL
	THROW 51000, 'Could not register oreder because there is no matching bill', 1
		-- Or exec addBill

	IF @online_order IS NULL
	THROW 51000, '@online_order is null', 1

	IF @company_order IS NULL
	THROW 51000, '@company_order is null', 1
	
	IF @company_order = 1
		
		IF @company_id IS NULL
		THROW 51000, '@company_id is null', 1
		-- Or exec addCompany
		
	
	
	IF @takeout IS NULL
	THROW 51000, '@takeout is null', 1

	IF ([dbo].[checkIfSeafoodAreAvailable](@order_id) = 0 )
	THROW 51000, '@the order has seafood which is unavailable today', 1


    IF ([dbo].[calculateAmountOfIndividualCustomerOrders](@customer_id) >= @amountOfOrdersForDiscount) 
		
		INSERT INTO bills
			(bill_id,
			discount,
			[status],
			invoice)
		VALUES
			(@bill_id
			,@repetitiveDiscount
			,@status
			,@invoice)
		

	INSERT INTO orders
        (customer_id
        ,created_at
        ,realization_time
        ,online_order
        ,company_order
        ,company_id
        ,takeout
		,bill_id)
    VALUES
        (@customer_id
        ,@created_at
        ,@realization_time
        ,@online_order
        ,@company_order
        ,@company_id
        ,@takeout
		,@bill_id)
	
	SET @order_id = SCOPE_IDENTITY();

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_alterdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_creatediagram]
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_dropdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagramdefinition]
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagrams]
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_MSforeach_worker]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
 
CREATE proc [dbo].[sp_MSforeach_worker]
	@command1 nvarchar(2000), @replacechar nchar(1) = N'?', @command2 nvarchar(2000) = null, @command3 nvarchar(2000) = null, @worker_type int =1
as
 
	create table #qtemp (	/* Temp command storage */
		qnum				int				NOT NULL,
		qchar				nvarchar(2000)	COLLATE database_default NULL
	)
 
	set nocount on
	declare @name nvarchar(517), @namelen int, @q1 nvarchar(2000), @q2 nvarchar(2000)
   declare @q3 nvarchar(2000), @q4 nvarchar(2000), @q5 nvarchar(2000)
	declare @q6 nvarchar(2000), @q7 nvarchar(2000), @q8 nvarchar(2000), @q9 nvarchar(2000), @q10 nvarchar(2000)
	declare @cmd nvarchar(2000), @replacecharindex int, @useq tinyint, @usecmd tinyint, @nextcmd nvarchar(2000)
   declare @namesave nvarchar(517), @nametmp nvarchar(517), @nametmp2 nvarchar(258)
 
	declare @local_cursor cursor
	if @worker_type=1	
		set @local_cursor = hCForEachDatabase
	else
		set @local_cursor = hCForEachTable
	
	open @local_cursor
	fetch @local_cursor into @name
 
	while (@@fetch_status >= 0) begin
 
      select @namesave = @name
		select @useq = 1, @usecmd = 1, @cmd = @command1, @namelen = datalength(@name)
		while (@cmd is not null) begin		/* Generate @q* for exec() */
			select @replacecharindex = charindex(@replacechar, @cmd)
			while (@replacecharindex <> 0) begin
 
            /* 7.0, if name contains ' character, and the name has been single quoted in command, double all of them in dbname */
            /* if the name has not been single quoted in command, do not doulbe them */
            /* if name contains ] character, and the name has been [] quoted in command, double all of ] in dbname */
            select @name = @namesave
            select @namelen = datalength(@name)
            declare @tempindex int
            if (substring(@cmd, @replacecharindex - 1, 1) = N'''') begin
               /* if ? is inside of '', we need to double all the ' in name */
               select @name = REPLACE(@name, N'''', N'''''')
            end else if (substring(@cmd, @replacecharindex - 1, 1) = N'[') begin
               /* if ? is inside of [], we need to double all the ] in name */
               select @name = REPLACE(@name, N']', N']]')
            end else if ((@name LIKE N'%].%]') and (substring(@name, 1, 1) = N'[')) begin
               /* ? is NOT inside of [] nor '', and the name is in [owner].[name] format, handle it */
               /* !!! work around, when using LIKE to find string pattern, can't use '[', since LIKE operator is treating '[' as a wide char */
               select @tempindex = charindex(N'].[', @name)
               select @nametmp  = substring(@name, 2, @tempindex-2 )
               select @nametmp2 = substring(@name, @tempindex+3, len(@name)-@tempindex-3 )
               select @nametmp  = REPLACE(@nametmp, N']', N']]')
               select @nametmp2 = REPLACE(@nametmp2, N']', N']]')
               select @name = N'[' + @nametmp + N'].[' + @nametmp2 + ']'
            end else if ((@name LIKE N'%]') and (substring(@name, 1, 1) = N'[')) begin
               /* ? is NOT inside of [] nor '', and the name is in [name] format, handle it */
               /* j.i.c., since we should not fall into this case */
               /* !!! work around, when using LIKE to find string pattern, can't use '[', since LIKE operator is treating '[' as a wide char */
               select @nametmp = substring(@name, 2, len(@name)-2 )
               select @nametmp = REPLACE(@nametmp, N']', N']]')
               select @name = N'[' + @nametmp + N']'
            end
            /* Get the new length */
            select @namelen = datalength(@name)
 
            /* start normal process */
				if (datalength(@cmd) + @namelen - 1 > 2000) begin
					/* Overflow; put preceding stuff into the temp table */
					if (@useq > 9) begin
						close @local_cursor
						if @worker_type=1	
							deallocate hCForEachDatabase
						else
							deallocate hCForEachTable
						return 1
					end
					if (@replacecharindex < @namelen) begin
						/* If this happened close to beginning, make sure expansion has enough room. */
						/* In this case no trailing space can occur as the row ends with @name. */
						select @nextcmd = substring(@cmd, 1, @replacecharindex)
						select @cmd = substring(@cmd, @replacecharindex + 1, 2000)
						select @nextcmd = stuff(@nextcmd, @replacecharindex, 1, @name)
						select @replacecharindex = charindex(@replacechar, @cmd)
						insert #qtemp values (@useq, @nextcmd)
						select @useq = @useq + 1
						continue
					end
					/* Move the string down and stuff() in-place. */
					/* Because varchar columns trim trailing spaces, we may need to prepend one to the following string. */
					/* In this case, the char to be replaced is moved over by one. */
					insert #qtemp values (@useq, substring(@cmd, 1, @replacecharindex - 1))
					if (substring(@cmd, @replacecharindex - 1, 1) = N' ') begin
						select @cmd = N' ' + substring(@cmd, @replacecharindex, 2000)
						select @replacecharindex = 2
					end else begin
						select @cmd = substring(@cmd, @replacecharindex, 2000)
						select @replacecharindex = 1
					end
					select @useq = @useq + 1
				end
				select @cmd = stuff(@cmd, @replacecharindex, 1, @name)
				select @replacecharindex = charindex(@replacechar, @cmd)
			end
 
			/* Done replacing for current @cmd.  Get the next one and see if it's to be appended. */
			select @usecmd = @usecmd + 1
			select @nextcmd = case (@usecmd) when 2 then @command2 when 3 then @command3 else null end
			if (@nextcmd is not null and substring(@nextcmd, 1, 2) = N'++') begin
				insert #qtemp values (@useq, @cmd)
				select @cmd = substring(@nextcmd, 3, 2000), @useq = @useq + 1
				continue
			end
 
			/* Now exec() the generated @q*, and see if we had more commands to exec().  Continue even if errors. */
			/* Null them first as the no-result-set case won't. */
			select @q1 = null, @q2 = null, @q3 = null, @q4 = null, @q5 = null, @q6 = null, @q7 = null, @q8 = null, @q9 = null, @q10 = null
			select @q1 = qchar from #qtemp where qnum = 1
			select @q2 = qchar from #qtemp where qnum = 2
			select @q3 = qchar from #qtemp where qnum = 3
			select @q4 = qchar from #qtemp where qnum = 4
			select @q5 = qchar from #qtemp where qnum = 5
			select @q6 = qchar from #qtemp where qnum = 6
			select @q7 = qchar from #qtemp where qnum = 7
			select @q8 = qchar from #qtemp where qnum = 8
			select @q9 = qchar from #qtemp where qnum = 9
			select @q10 = qchar from #qtemp where qnum = 10
			truncate table #qtemp
			exec (@q1 + @q2 + @q3 + @q4 + @q5 + @q6 + @q7 + @q8 + @q9 + @q10 + @cmd)
			select @cmd = @nextcmd, @useq = 1
		end
    fetch @local_cursor into @name
	end /* while FETCH_SUCCESS */
	close @local_cursor
	if @worker_type=1	
		deallocate hCForEachDatabase
	else
		deallocate hCForEachTable
		
	return 0
 
GO
/****** Object:  StoredProcedure [dbo].[sp_MSforeachtable]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_MSforeachtable]
	@command1 nvarchar(2000), @replacechar nchar(1) = N'?', @command2 nvarchar(2000) = null,
  @command3 nvarchar(2000) = null, @whereand nvarchar(2000) = null,
	@precommand nvarchar(2000) = null, @postcommand nvarchar(2000) = null
AS
	declare @mscat nvarchar(12)
	select @mscat = ltrim(str(convert(int, 0x0002)))
	if (@precommand is not null)
		exec(@precommand)
   exec(N'declare hCForEachTable cursor global for select ''['' + REPLACE(schema_name(syso.schema_id), N'']'', N'']]'') + '']'' + ''.'' + ''['' + REPLACE(object_name(o.id), N'']'', N'']]'') + '']'' from dbo.sysobjects o join sys.all_objects syso on o.id = syso.object_id '
         + N' where OBJECTPROPERTY(o.id, N''IsUserTable'') = 1 ' + N' and o.category & ' + @mscat + N' = 0 '
         + @whereand)
	declare @retval int
	select @retval = @@error
	if (@retval = 0)
		exec @retval = dbo.sp_MSforeach_worker @command1, @replacechar, @command2, @command3, 0
	if (@retval = 0 and @postcommand is not null)
		exec(@postcommand)
	return @retval
GO
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_renamediagram]
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_updateTable]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      PBD grupa 2
-- Create Date: 
-- Description: Edytowanie ilosci miejsc
-- =============================================
CREATE PROCEDURE [dbo].[sp_updateTable]
(
    -- Add the parameters for the stored procedure here
	@table_id INT,
	@newCapacity INT
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

    -- Insert statements for procedure here
    BEGIN TRY
	BEGIN TRANSACTION;

	  IF @table_id IS NULL
		THROW 51000, 'Nr stolika jest niepoprawny', 1

	  IF @newCapacity IS NULL 
		THROW 51000, 'Ilosc miejsc jest niepoprawna', 1

      IF  0 >= @newCapacity 
		THROW 51000, 'Ilosc miejsc jest niepoprawna', 1

	UPDATE tables
	SET seats = @newCapacity
	WHERE tables.table_id = @table_id

	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 10/06/2021 23:06:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_upgraddiagrams]
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END
	
GO
EXEC sys.sp_addextendedproperty @name=N'microsoft_database_tools_support', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'sysdiagrams'
GO
ALTER DATABASE [pdb-projekt] SET  READ_WRITE 
GO
