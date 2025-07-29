# 🛰 Manufacturing-Operations-Research-Project-OR-Cost-Minimisation-Profit-Maximisation
This end-to-end SQLite project respository models and analyses cost minimisation and profit maximisation in manufacturing plant using advanced SQL

---

## 🛥 Overview
This repository tackles real manufacturing business problems: deciding optimal production mix, raw material procurement, and line usage to maximize profit and minimize cost, accounting for constraints like machine hours, workforce and supply limits

---

## 🛝 Business problem
Factories face choices:
- Which products to make, and in what quantities, to make maximum profit?
- How to allocate resources, purchase materials, and schedule lines to minimize costs - given real constraints?

---

## 🛕 Linear Programming Model 
While SQL can't do true linear/MILP optimization, we can derive optimal plans heuristically by:
- calculating max possible output for each product under each constraint
- identifying bottleneck (smallest limiting factor for each product)
- computing scenarios: all profit-maximization, all cost-minimisation

---

## 🏚 SQL Queries used
- SELECT()
- FROM()
- ON()
- WHERE()
- JOIN()
- WITH()
- SUM()
- PRIMARY KEY()
- AUTOINCREMENT()
- GROUP BY()
- ORDER BY()
- DESC()
- MIN()
- FOREIGN KEY()
- REFERENCES()
- MIN()

---

## 🏫 Requirements
- DBeaver > SQLite
- Fundamentals of Database Management System
- Fundamentals of Operations Research

---

*"The conclusions of most good operations research studies are obvious" - Robert E. Machol*
