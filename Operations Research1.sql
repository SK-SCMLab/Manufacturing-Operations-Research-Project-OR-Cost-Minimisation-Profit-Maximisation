-- List of Finished Goods (FG) produced
CREATE TABLE products3(
	product_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT,
	unit_profit REAL, -- profit per unit sold
	unit_price REAL, -- price per unit (revenue)
	unit_cost REAL -- cost per unit (for cost minimization)
);
SELECT * FROM products3;

-- Raw materials used in production
CREATE TABLE raw_materials(
	material_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT,
	unit_cost REAL, -- per unit purchase cost
	available_qty REAL -- max supplier cap for this planning horizon
);
SELECT * FROM raw_materials;

-- Bill of Materials (per unit product usage of raw materials)
CREATE TABLE bom1(
	bom_id INTEGER PRIMARY KEY AUTOINCREMENT,
	product_id INTEGER,
	material_id INTEGER,
	qty_per_unit REAL,
	FOREIGN KEY (product_id) REFERENCES products3(product_id),
	FOREIGN KEY (material_id) REFERENCES raw_materials(material_id)
);
SELECT * FROM bom1;

-- Production line constraints
CREATE TABLE lines(
	line_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT,
	max_available_hours REAL
);
SELECT * FROM lines;

-- Product routing:: line usage per product (how many hours per unit)
CREATE TABLE routing(
	routing_id INTEGER PRIMARY KEY AUTOINCREMENT,
	product_id INTEGER,
	line_id INTEGER,
	hours_per_unit REAL,
	FOREIGN KEY (product_id) REFERENCES products3(product_id),
	FOREIGN KEY (line_id) REFERENCES lines(line_id)
);
SELECT * FROM routing;

-- Demand forecast per product (use for profit maximisation)
CREATE TABLE demand_forecast(
	forecast_id INTEGER PRIMARY KEY AUTOINCREMENT,
	product_id INTEGER,
	max_demand_qty REAL,
	FOREIGN KEY (product_id) REFERENCES products3(product_id)
);
SELECT * FROM demand_forecast;

-- Products
INSERT INTO products3(name, unit_profit, unit_price, unit_cost) VALUES
('Widget A', 120, 350, 230),
('Widget B', 90, 250, 160),
('Widget C', 200, 700, 500);

-- Raw materials
INSERT INTO raw_materials(name, unit_cost, available_qty) VALUES
('Steel', 45, 1000),
('Plastic', 25, 800),
('Copper', 200, 400),
('Packaging', 10, 1000);

-- BOM (per unit)
INSERT INTO bom1(product_id, material_id, qty_per_unit) VALUES
(1, 1, 2), -- Widget A:: 2 Steel
(1, 2, 1), -- Widget A:: 1 Plastic
(1, 4, 1), -- Widget A:: 1 Packaging
(2, 1, 1.5), -- Widget B:: 1.5 Steel
(2, 2, 1.5), -- Widget B:: 1.5 Plastic
(2, 4, 1), -- Widget B:: 1 Packaging
(3, 1, 1), -- Gadget C:: 1 Steel
(3, 3, 2), -- Gadget C:: 2 Copper
(3, 4, 2); -- Gadget C:: 1 Packaging 

-- Lines
INSERT INTO lines(name, max_available_hours) VALUES
('Assembly Line 1', 500 ),
('Assembly Line 2', 320);

-- Routing (Line hours per unit)
INSERT INTO routing(product_id, line_id, hours_per_unit) VALUES
(1, 1, 2.5), -- Widget A, Line 1
(2, 1, 1.8), -- Widget B, Line 2
(2, 2, 2.2), -- Widget B, Line 2 (alternate routing)
(3, 2, 3.5); -- Gadget C, Line 2

-- Demand forecasts
INSERT INTO demand_forecast(product_id, max_demand_qty) VALUES
(1, 200), -- Widget A
(2, 220), -- Widget B
(3, 80); -- Gadget C

-- 1. Max possible by raw material
WITH max_by_material AS (
	SELECT
		p.product_id,
		p.name,
		MIN(rm.available_qty / b.qty_per_unit) AS max_by_material
	FROM products3 p
	JOIN bom1 b ON p.product_id = b.product_id
	JOIN raw_materials rm ON b.material_id = rm.material_id
	GROUP BY p.product_id
),

-- 2. Max possible by line hour
max_by_line AS (
	SELECT
		p.product_id,
		MIN(lines.max_available_hours / routing.hours_per_unit) AS max_by_line
	FROM products3 p
	JOIN routing ON p.product_id = routing.product_id
	JOIN lines ON routing.line_id = lines.line_id
	GROUP BY p.product_id
),

-- 3. Max by demand
max_by_demand AS (
	SELECT product_id, max_demand_qty FROM demand_forecast
), 

-- Combine Constraints
product_limits AS (
	SELECT 
		p.product_id,
		p.name,
		MIN(max_by_material) AS max_by_material,
		(SELECT max_by_line FROM max_by_line mbl WHERE mbl.product_id = p.product_id) AS max_by_line,
		(SELECT max_demand_qty FROM max_by_demand mbd WHERE mbd.product_id = p.product_id) AS max_by_demand
	FROM products3 p
	JOIN max_by_material mbm ON p.product_id = mbm.product_id
	GROUP BY p.product_id
)
SELECT
	product_id,
	name,
	ROUND(MIN(max_by_material, max_by_line, max_by_demand), 2) AS max_feasible_qty,
	ROUND(max_by_material, 2) AS limit_material,
	ROUND(max_by_line, 2) AS limit_line,
	max_by_demand AS limit_demand
FROM product_limits;

-- Order products by descending profit per unit, allocate resources greedily
WITH ordered_limits AS (
	SELECT
		pl.product_id,
		pl.name,
		pl.max_feasible_qty,
		p.unit_profit
	FROM (
		-- Use "max feasible qty" from previous query as CTE or paste it here
	SELECT 
		p.product_id,
		p.name,
		ROUND(MIN(
				mbm.max_by_material,
				mbl.max_by_line,
				mbd.max_demand_qty
			), 2) AS max_feasible_qty
		FROM products3 p
		JOIN (
			SELECT
				b.product_id,
				MIN(rm.available_qty / b.qty_per_unit) AS max_by_material
			FROM bom1 b
			JOIN raw_materials rm ON b.material_id = rm.material_id
			GROUP BY b.product_id
		) mbm ON p.product_id = mbm.product_id
		JOIN (
			SELECT 
				routing.product_id,
				MIN(lines.max_available_hours / routing.hours_per_unit) AS max_by_line
			FROM routing
			JOIN lines ON routing.line_id = lines.line_id
			GROUP BY routing.product_id 
		) mbl ON p.product_id = mbl.product_id
		JOIN (
			SELECT product_id, max_demand_qty FROM demand_forecast
		) mbd ON p.product_id  = mbd.product_id
		) pl 
		JOIN products3 p ON pl.product_id = p.product_id
		ORDER BY p.unit_profit DESC
	)
	SELECT
		product_id,
		name,
		unit_profit,
		max_feasible_qty,
		(unit_profit * max_feasible_qty) AS max_possible_profit
	FROM ordered_limits
	ORDER BY unit_profit DESC;

-- Example:: For the planned output (see "max_feasible_qty" for each product), compute material and line hour costs
-- Set product constraints (allocate a business target, e.g. demand or max feasible)
WITH planned_output AS (
	SELECT product_id, max_feasible_qty AS planned_qty
	FROM (
		-- Copy "max_feasible_qty" query here or set manually (as a scenario)
	SELECT 
		p.product_id,
		MIN (
			(SELECT MIN(rm.available_qty / b.qty_per_unit)
			 FROM bom1 b JOIN raw_materials rm ON b.material_id = rm.material_id
			 WHERE b.product_id = p.product_id),
			(SELECT MIN(lines.max_available_hours / routing.hours_per_unit)
			 FROM routing JOIN lines ON routing.line_id = lines.line_id
			 WHERE routing.product_id = p.product_id),
			(SELECT max_demand_qty FROM demand_forecast WHERE product_id = p.product_id)
			) AS max_feasible_qty
			FROM products3 p
		)
	),
	mat_req AS (
		SELECT
			po.product_id, po.planned_qty, b.material_id, b.qty_per_unit,
			(po.planned_qty * b.qty_per_unit) AS total_required
		FROM planned_output po
		JOIN bom1 b ON po.product_id = b.product_id
	), 
	mat_cost AS (
		SELECT
			mr.product_id,
			rm.name AS material,
			mr.total_required,
			rm.unit_cost,
			(mr.total_required * rm.unit_cost) AS material_cost
		FROM mat_req mr
		JOIN raw_materials rm ON mr.material_id = rm.material_id
	),
	prod_line_hours AS (
		SELECT
			po.product_id,
			po.planned_qty,
			l.name AS line,
			r.hours_per_unit,
			(po.planned_qty * r.hours_per_unit) AS required_hours
		FROM planned_output po
		JOIN routing r ON po.product_id = r.product_id
		JOIN lines l ON r.line_id = l.line_id
	)
	SELECT
		m.product_id, 
		SUM(m.material_cost) AS total_material_cost,
		SUM(pl.required_hours) AS total_line_hours
	FROM mat_cost m
	JOIN prod_line_hours pl ON m.product_id = pl.product_id
	GROUP BY m.product_id; 