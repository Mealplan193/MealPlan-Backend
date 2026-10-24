BEGIN TRANSACTION;
CREATE TABLE entries (
    entry_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id             INTEGER REFERENCES foods(food_id) ON DELETE SET NULL,
    food_name           TEXT NOT NULL,
    measure             TEXT NOT NULL,
    emoji               TEXT NOT NULL DEFAULT '🍽️',
    quantity            REAL NOT NULL CHECK (quantity >= 0.25),
    calories            REAL NOT NULL,
    protein             REAL NOT NULL,
    carbs               REAL NOT NULL,
    fat                 REAL NOT NULL,
    predicted_group_id  INTEGER NOT NULL REFERENCES food_groups(group_id),
    final_group_id      INTEGER NOT NULL REFERENCES food_groups(group_id),
    prediction_confidence REAL,
    entry_date          TEXT NOT NULL,          -- YYYY-MM-DD
    entry_time          TEXT NOT NULL,          -- HH:MM
    created_at          TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "entries" VALUES(1,16,'Oatmeal','1 cup','🥣',1.0,154.0,6.0,27.0,3.2,5,5,9.57276222737172499e-01,'2026-10-24','07:30','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(2,1,'Banana','1 medium','🍌',2.0,210.0,2.6,54.0,0.8,1,1,9.61461597569992498e-01,'2026-10-24','07:45','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(3,10,'Chicken breast','100 g','🍗',1.5,247.5,46.5,0.0,5.4,4,4,9.3677172035404721e-01,'2026-10-24','12:15','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(4,15,'Brown rice','1 cup','🍚',1.0,216.0,5.0,45.0,1.8,5,5,8.70480176584517373e-01,'2026-10-24','12:15','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(5,21,'Almonds','28 g','🥜',1.0,164.0,6.0,6.1,14.2,7,7,9.44414861872671096e-01,'2026-10-24','15:30','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(6,11,'Egg','1 large','🥚',2.0,144.0,12.6,0.8,9.6,2,2,2.64692658999420737e-01,'2026-10-23','08:00','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(7,17,'Whole wheat bread','1 slice','🍞',2.0,162.0,8.0,28.0,2.2,5,5,9.83614124450182703e-01,'2026-10-23','08:00','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(8,12,'Salmon','100 g','🐟',1.5,312.0,30.0,0.0,19.5,4,4,9.60166863133145476e-01,'2026-10-23','19:00','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(9,6,'Broccoli','1 cup','🥦',1.0,55.0,3.7,11.2,0.6,2,2,9.64882645734871702e-01,'2026-10-23','19:00','2026-10-24 15:42:21');
INSERT INTO "entries" VALUES(10,29,'Vanilla ice cream','1/2 cup','🍨',1.0,137.0,2.3,16.0,7.0,6,6,9.76771543253195817e-01,'2026-10-23','20:30','2026-10-24 15:42:21');
CREATE TABLE food_groups (
    group_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT NOT NULL UNIQUE
);
INSERT INTO "food_groups" VALUES(1,'Fruits');
INSERT INTO "food_groups" VALUES(2,'Vegetables');
INSERT INTO "food_groups" VALUES(3,'Desserts');
INSERT INTO "food_groups" VALUES(4,'Protein');
INSERT INTO "food_groups" VALUES(5,'Grains and carbs');
INSERT INTO "food_groups" VALUES(6,'Dairy');
INSERT INTO "food_groups" VALUES(7,'Nuts and seeds');
INSERT INTO "food_groups" VALUES(8,'Fats and oils');
INSERT INTO "food_groups" VALUES(9,'Beverages');
INSERT INTO "food_groups" VALUES(10,'Snacks');
CREATE TABLE foods (
    food_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT NOT NULL UNIQUE COLLATE NOCASE,
    group_id   INTEGER NOT NULL REFERENCES food_groups(group_id),
    measure    TEXT NOT NULL DEFAULT '1 serving',
    calories   REAL NOT NULL CHECK (calories >= 0),
    protein    REAL NOT NULL CHECK (protein  >= 0),
    carbs      REAL NOT NULL CHECK (carbs    >= 0),
    fat        REAL NOT NULL CHECK (fat      >= 0),
    emoji      TEXT NOT NULL DEFAULT '🍽️',
    is_builtin INTEGER NOT NULL DEFAULT 0 CHECK (is_builtin IN (0, 1))
);
INSERT INTO "foods" VALUES(1,'Banana',1,'1 medium',105.0,1.3,27.0,0.4,'🍌',1);
INSERT INTO "foods" VALUES(2,'Apple',1,'1 medium',95.0,0.5,25.0,0.3,'🍎',1);
INSERT INTO "foods" VALUES(3,'Orange',1,'1 medium',62.0,1.2,15.4,0.2,'🍊',1);
INSERT INTO "foods" VALUES(4,'Mango',1,'1 cup',99.0,1.4,25.0,0.6,'🥭',1);
INSERT INTO "foods" VALUES(5,'Strawberries',1,'1 cup',49.0,1.0,12.0,0.5,'🍓',1);
INSERT INTO "foods" VALUES(6,'Broccoli',2,'1 cup',55.0,3.7,11.2,0.6,'🥦',1);
INSERT INTO "foods" VALUES(7,'Carrot',2,'1 medium',25.0,0.6,6.0,0.1,'🥕',1);
INSERT INTO "foods" VALUES(8,'Spinach',2,'1 cup',7.0,0.9,1.1,0.1,'🥬',1);
INSERT INTO "foods" VALUES(9,'Tomato',2,'1 medium',22.0,1.1,4.8,0.2,'🍅',1);
INSERT INTO "foods" VALUES(10,'Chicken breast',4,'100 g',165.0,31.0,0.0,3.6,'🍗',1);
INSERT INTO "foods" VALUES(11,'Egg',4,'1 large',72.0,6.3,0.4,4.8,'🥚',1);
INSERT INTO "foods" VALUES(12,'Salmon',4,'100 g',208.0,20.0,0.0,13.0,'🐟',1);
INSERT INTO "foods" VALUES(13,'Tofu',4,'100 g',76.0,8.0,1.9,4.8,'◻️',1);
INSERT INTO "foods" VALUES(14,'White rice',5,'1 cup',205.0,4.3,44.5,0.4,'🍚',1);
INSERT INTO "foods" VALUES(15,'Brown rice',5,'1 cup',216.0,5.0,45.0,1.8,'🍚',1);
INSERT INTO "foods" VALUES(16,'Oatmeal',5,'1 cup',154.0,6.0,27.0,3.2,'🥣',1);
INSERT INTO "foods" VALUES(17,'Whole wheat bread',5,'1 slice',81.0,4.0,14.0,1.1,'🍞',1);
INSERT INTO "foods" VALUES(18,'Milk',6,'1 cup',122.0,8.0,12.0,4.8,'🥛',1);
INSERT INTO "foods" VALUES(19,'Yogurt, plain',6,'1 cup',149.0,8.5,11.4,8.0,'🥣',1);
INSERT INTO "foods" VALUES(20,'Cheddar cheese',6,'1 slice',113.0,7.0,0.4,9.3,'🧀',1);
INSERT INTO "foods" VALUES(21,'Almonds',7,'28 g',164.0,6.0,6.1,14.2,'🥜',1);
INSERT INTO "foods" VALUES(22,'Peanut butter',7,'2 tbsp',188.0,7.0,7.0,16.0,'🥜',1);
INSERT INTO "foods" VALUES(23,'Olive oil',8,'1 tbsp',119.0,0.0,0.0,13.5,'🫒',1);
INSERT INTO "foods" VALUES(24,'Avocado',8,'1/2 fruit',120.0,1.5,6.4,11.0,'🥑',1);
INSERT INTO "foods" VALUES(25,'Orange juice',9,'1 cup',112.0,1.7,25.8,0.5,'🧃',1);
INSERT INTO "foods" VALUES(26,'Coffee, black',9,'1 cup',2.0,0.3,0.0,0.0,'☕',1);
INSERT INTO "foods" VALUES(27,'Potato chips',10,'28 g',152.0,2.0,15.0,10.0,'🥔',1);
INSERT INTO "foods" VALUES(28,'Dark chocolate',3,'30 g',170.0,2.2,13.0,12.0,'🍫',1);
INSERT INTO "foods" VALUES(29,'Vanilla ice cream',3,'1/2 cup',137.0,2.3,16.0,7.0,'🍨',1);
INSERT INTO "foods" VALUES(30,'Popcorn, air-popped',10,'3 cups',93.0,3.0,19.0,1.1,'🍿',1);
INSERT INTO "foods" VALUES(31,'Cows'' Milk',6,'1 qt.',660.0,32.0,48.0,40.0,'🍽️',1);
INSERT INTO "foods" VALUES(32,'Milk Skim',6,'1 qt.',360.0,36.0,52.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(33,'Buttermilk',6,'1 cup',127.0,9.0,13.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(34,'Evaporated, Undiluted',6,'1 cup',345.0,16.0,24.0,20.0,'🍽️',1);
INSERT INTO "foods" VALUES(35,'Fortified Milk',6,'6 cups',1373.0,89.0,119.0,42.0,'🍽️',1);
INSERT INTO "foods" VALUES(36,'Powdered Milk',6,'1 cup',515.0,27.0,39.0,28.0,'🍽️',1);
INSERT INTO "foods" VALUES(37,'Skim, Instant',6,'1 1/3 cups',290.0,30.0,42.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(38,'Skim, Non-Instant',6,'2/3 cup',290.0,30.0,42.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(39,'Goats'' Milk',6,'1 cup',165.0,8.0,11.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(40,'(1/2 Cup Ice Cream)',6,'2 cups',690.0,24.0,70.0,24.0,'🍽️',1);
INSERT INTO "foods" VALUES(41,'Cocoa',6,'1 cup',235.0,8.0,26.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(42,'Skim. Milk',6,'1 cup',128.0,18.0,13.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(43,'(Cornstarch)',6,'1 cup',275.0,9.0,40.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(44,'Custard',6,'1 cup',285.0,13.0,28.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(45,'Ice Cream',6,'1 cup',300.0,6.0,29.0,18.0,'🍽️',1);
INSERT INTO "foods" VALUES(46,'Ice Milk',6,'1 cup',275.0,9.0,32.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(47,'Cream Or Half-And-Half',6,'1/2 cup',170.0,4.0,5.0,15.0,'🍽️',1);
INSERT INTO "foods" VALUES(48,'Or Whipping',6,'1/2 cup',430.0,2.0,3.0,44.0,'🍽️',1);
INSERT INTO "foods" VALUES(49,'Cheese',6,'1 cup',240.0,30.0,6.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(50,'Uncreamed',6,'1 cup',195.0,38.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(51,'Cheddar',6,'1-in. cube',70.0,4.0,0.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(52,'Cheddar, Grated Cup',6,'1/2 cup',226.0,14.0,1.0,19.0,'🍽️',1);
INSERT INTO "foods" VALUES(53,'Cream Cheese',6,'1 oz.',105.0,2.0,1.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(54,'Processed Cheese',6,'1 oz.',105.0,7.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(55,'Roquefort Type',6,'1 oz.',105.0,6.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(56,'Swiss',6,'1 oz.',105.0,7.0,0.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(57,'Eggs Raw',6,'2',150.0,12.0,0.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(58,'Eggs Scrambled Or Fried',6,'2',220.0,13.0,1.0,16.0,'🍽️',1);
INSERT INTO "foods" VALUES(59,'Yolks',8,'2',120.0,6.0,0.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(60,'Butter',8,'1T.',100.0,0.0,0.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(61,'Hydrogenated Cooking Fat',8,'1/2 cup',665.0,0.0,0.0,100.0,'🍽️',1);
INSERT INTO "foods" VALUES(62,'Lard',8,'1/2 cup',992.0,0.0,0.0,110.0,'🍽️',1);
INSERT INTO "foods" VALUES(63,'Margarine',8,'1/2 cup',806.0,0.0,0.0,91.0,'🍽️',1);
INSERT INTO "foods" VALUES(64,'Margarine, 2 Pat Or',8,'1 T.',100.0,0.0,0.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(65,'Mayonnaise',8,'1 T.',110.0,0.0,0.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(66,'Corn Oil',8,'1 T.',125.0,0.0,0.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(68,'Safflower Seed Oil',8,'1 T.',125.0,0.0,0.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(69,'French Dressing',8,'1 T.',60.0,0.0,2.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(70,'Thousand Island Sauce',8,'1 T.',75.0,0.0,1.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(71,'Salt Pork',4,'2 oz.',470.0,3.0,0.0,55.0,'🍽️',1);
INSERT INTO "foods" VALUES(72,'Bacon',4,'2 slices',95.0,4.0,1.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(73,'Beef',4,'3 oz.',245.0,23.0,0.0,16.0,'🍽️',1);
INSERT INTO "foods" VALUES(74,'Hamburger',4,'3 oz.',245.0,21.0,0.0,17.0,'🍽️',1);
INSERT INTO "foods" VALUES(75,'Ground Lean',4,'3 oz.',185.0,24.0,0.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(76,'Roast Beef',4,'3 oz.',390.0,16.0,0.0,36.0,'🍽️',1);
INSERT INTO "foods" VALUES(77,'Steak',4,'3 oz.',330.0,20.0,0.0,27.0,'🍽️',1);
INSERT INTO "foods" VALUES(78,'Steak, Lean, As Round',4,'3 oz.',220.0,24.0,0.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(79,'Corned Beef',4,'3 oz.',185.0,22.0,0.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(80,'Corned Beef Hash Canned',4,'3 oz.',120.0,12.0,6.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(81,'Corned Beef Hash Dried',4,'2 oz.',115.0,19.0,0.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(82,'Pot-Pie',4,'1 pie',480.0,18.0,32.0,28.0,'🍽️',1);
INSERT INTO "foods" VALUES(83,'Corned Beef Hash Stew',4,'1 cup',185.0,15.0,15.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(84,'Chicken',4,'3 oz.',185.0,23.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(85,'Fried, Breast Or Leg And Thigh Chicken',4,'3 oz.',245.0,25.0,0.0,15.0,'🍽️',1);
INSERT INTO "foods" VALUES(86,'Roasted Chicken',4,'3 1/2 oz.',290.0,25.0,0.0,20.0,'🍽️',1);
INSERT INTO "foods" VALUES(87,'Chicken Livers, Fried',4,'3 med.',140.0,22.0,2.3,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(88,'Duck, Domestic',4,'3 1/2 oz.',370.0,16.0,0.0,28.0,'🍽️',1);
INSERT INTO "foods" VALUES(89,'Lamb, Chop, Broiled',4,'4 oz.',480.0,24.0,0.0,35.0,'🍽️',1);
INSERT INTO "foods" VALUES(90,'Leg Roasted',4,'3 oz.',314.0,20.0,0.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(91,'Shoulder, Braised',4,'3 oz.',285.0,18.0,0.0,23.0,'🍽️',1);
INSERT INTO "foods" VALUES(92,'Pork, Chop, 1 Thick',4,'3 1/2 oz.',260.0,16.0,0.0,21.0,'🍽️',1);
INSERT INTO "foods" VALUES(93,'Ham Pan-Broiled',4,'3 oz.',290.0,16.0,0.0,22.0,'🍽️',1);
INSERT INTO "foods" VALUES(94,'Ham, As',4,'2 oz.',170.0,13.0,0.0,13.0,'🍽️',1);
INSERT INTO "foods" VALUES(95,'Ham, Canned, Spiced',4,'2 oz.',165.0,8.0,1.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(96,'Pork Roast',4,'3 oz.',310.0,21.0,0.0,24.0,'🍽️',1);
INSERT INTO "foods" VALUES(97,'Pork Sausage',4,'3 1/2 oz.',475.0,18.0,0.0,44.0,'🍽️',1);
INSERT INTO "foods" VALUES(98,'Turkey',4,'3 1/2 oz.',265.0,27.0,0.0,15.0,'🍽️',1);
INSERT INTO "foods" VALUES(99,'Veal',4,'3 oz.',185.0,23.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(100,'Roast',4,'3 oz.',305.0,13.0,0.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(101,'Clams',4,'3 oz.',87.0,12.0,2.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(102,'Cod',4,'3 1/2 oz.',170.0,28.0,0.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(103,'Crab Meat',4,'3 oz.',90.0,14.0,1.0,2.0,'🍽️',1);
INSERT INTO "foods" VALUES(104,'Fish Sticks Fried',4,'5',200.0,19.0,8.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(105,'Flounder',4,'3 1/2 oz.',200.0,30.0,0.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(106,'Haddock',4,'3 oz.',135.0,16.0,6.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(107,'Halibut',4,'3 1/2 oz.',182.0,26.0,0.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(108,'Herring',4,'1 small',211.0,22.0,0.0,13.0,'🍽️',1);
INSERT INTO "foods" VALUES(109,'Lobster',4,'aver.',92.0,18.0,0.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(110,'Mackerel',4,'3 oz.',155.0,18.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(111,'Oysters',4,'6-8 med.',231.0,232.0,236.0,233.0,'🍽️',1);
INSERT INTO "foods" VALUES(112,'Oyster Stew',4,'1 cup',125.0,19.0,0.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(114,'Sardines',4,'3 oz.',180.0,22.0,0.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(115,'Scallops',4,'3 1/2 oz.',104.0,18.0,10.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(116,'Shad',4,'3 oz.',170.0,20.0,0.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(117,'Shrimp',4,'3 oz.',110.0,23.0,0.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(118,'Swordfish',4,'1 steak',180.0,27.0,0.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(119,'Tuna',4,'3 oz.',170.0,25.0,0.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(120,'Asparagus',2,'6 spears',18.0,1.0,3.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(121,'Beans',2,'1 cup',25.0,1.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(122,'Lima',2,'1 cup',140.0,8.0,24.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(123,'Lima, Dry, Cooked',2,'1 cup',260.0,16.0,48.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(124,'Navy, Baked With Pork',2,'3/4 cup',250.0,11.0,37.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(125,'Red Kidney',2,'1 cup',230.0,15.0,42.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(126,'Bean Sprouts',2,'1 cup',17.0,1.0,3.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(127,'Beet Greens',2,'1 cup',27.0,2.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(128,'Beetroots',2,'1 cup',1.0,12.0,0.8,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(130,'Brussels Sprouts',2,'1 cup',60.0,6.0,12.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(131,'Sauerkraut',2,'1 cup',32.0,1.0,7.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(132,'Steamed Cabbage',2,'1 cup',40.0,2.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(133,'Carrots',2,'1 cup',45.0,1.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(134,'Raw, Grated',2,'1 cup',45.0,1.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(135,'Strips, From Raw',2,'1 mad.',20.0,0.0,5.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(136,'Cauliflower',2,'1 cup',30.0,3.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(137,'Celery',2,'1 cup',20.0,1.0,4.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(138,'Stalk Raw',2,'1 large',5.0,1.0,1.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(139,'Chard Steamed',2,'1 cup',30.0,2.0,7.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(140,'Collards',2,'1 cup',51.0,5.0,8.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(141,'Corn',2,'1 ear',92.0,3.0,21.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(142,'Cooked Or Canned',2,'1 cup',170.0,5.0,41.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(143,'Cucumbers',2,'8',6.0,0.0,1.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(144,'Dandelion Greens',2,'1 cup',80.0,5.0,16.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(145,'Eggplant',2,'1 cup',30.0,2.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(146,'Endive',2,'2 oz.',10.0,1.0,2.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(147,'Kale',2,'1 cup',45.0,4.0,8.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(148,'Kohlrabi',2,'1 cup',40.0,2.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(149,'Lambs Quarters, Steamed',2,'1 cup',48.0,5.0,7.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(150,'Lentils',2,'1 cup',212.0,15.0,38.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(151,'Lettuce',2,'1/4 head',14.0,1.0,2.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(152,'Iceberg',2,'1/4 head',13.0,0.0,3.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(153,'Mushrooms Canned',2,'4',12.0,2.0,4.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(154,'Mustard Greens',2,'1',30.0,3.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(155,'Okra',2,'1 1/3 cups',32.0,1.0,7.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(156,'Onions',2,'1',80.0,2.0,18.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(157,'Raw, Green',2,'6 small',22.0,0.0,5.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(158,'Parsley',2,'2 T.',2.0,0.0,0.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(159,'Parsnips',2,'1 cup',95.0,2.0,22.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(160,'Peas',2,'1 cup',66.0,3.0,13.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(161,'Fresh, Steamed Peas',2,'1 cup',70.0,5.0,12.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(162,'Split Cooked Peas',2,'4 cups',115.0,8.0,21.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(163,'Heated Peas',2,'1 cup',53.0,3.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(164,'Peppers Canned',2,'1 pod',10.0,0.0,2.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(165,'Peppers Raw, Green, Sweet',2,'1 large',25.0,1.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(166,'Peppers With Beef And Crumbs',2,'1 med.',255.0,19.0,24.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(167,'Potatoes, Baked',2,'1 med.',100.0,2.0,22.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(168,'Potatoes Mashed With Milk And Butter',2,'1 cup',230.0,4.0,28.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(169,'Potatoes, Pan-Tried',2,'3/4 cup',268.0,4.0,33.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(170,'Scalloped With Cheese Potatoes',2,'3/4 cup',145.0,6.0,14.0,8.0,'🍽️',1);
INSERT INTO "foods" VALUES(171,'Steamed Potatoes Before Peeling',2,'1 med.',80.0,2.0,19.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(173,'Radishes',2,'5 small',10.0,0.0,2.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(174,'Rutabagas',2,'4 cups',32.0,0.0,8.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(175,'Soybeans',2,'1 cup',260.0,22.0,20.0,11.0,'🍽️',1);
INSERT INTO "foods" VALUES(177,'Squash',2,'1 cup',35.0,1.0,8.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(178,'Winter, Mashed',2,'1 cup',95.0,4.0,23.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(179,'Sweet Potatoes',2,'1 med.',155.0,2.0,36.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(180,'Candied',2,'1 med.',235.0,2.0,80.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(181,'Tomatoes',2,'1 cup',50.0,2.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(182,'Raw, 2 By 2 1/2',2,'1 med.',30.0,1.0,6.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(183,'Tomato Juice',2,'1 cup',50.0,2.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(184,'Tomato Catsup',2,'1 T.',15.0,0.0,4.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(185,'Turnip Greens',2,'1 cup',45.0,4.0,8.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(186,'Turnips, Steamed',2,'1 cup',40.0,1.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(187,'Watercress Stems, Raw',1,'1 cup',9.0,1.0,1.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(188,'Apple Juice Canned',1,'1 cup',125.0,0.0,34.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(189,'Apple Vinegar',1,'1/3 cup',14.0,0.0,3.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(190,'Apples, Raw',1,'1 med',70.0,0.0,18.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(191,'Stewed Or Canned',1,'1 cup',100.0,0.0,26.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(192,'Apricots',1,'1 cup',220.0,2.0,57.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(193,'Dried, Uncooked',1,'1/2 cup',220.0,4.0,50.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(194,'Fresh',1,'3 med.',55.0,1.0,14.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(195,'Nectar, Or Juice',1,'1 cup',140.0,1.0,36.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(198,'Blackberries',1,'1 cup',85.0,2.0,19.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(199,'Blueberries',1,'1 cup',245.0,1.0,65.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(200,'Cantaloupe',1,'1/2 med.',40.0,1.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(201,'Cherries',1,'1 cup',100.0,2.0,26.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(202,'Fresh, Raw',1,'1 cup',65.0,1.0,15.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(203,'Cranberry Sauce Sweetened',1,'1 cup',530.0,0.0,142.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(204,'Dates',1,'1 cup',505.0,4.0,134.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(205,'Figs',1,'2',120.0,2.0,30.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(206,'Fresh, Raw Figs',1,'3 med.',90.0,2.0,22.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(207,'Figs Canned With Syrup',1,'3',130.0,1.0,32.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(208,'Fruit Cocktail, Canned',1,'1 cup',195.0,1.0,50.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(209,'Grapefruit Sections',1,'1 cup',170.0,1.0,44.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(210,'Grapefruit, Fresh, 5" Diameter',1,'1/2',50.0,1.0,14.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(211,'Grapefruit Juice',1,'1 cup',100.0,1.0,24.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(212,'Grapes',1,'1 cup',70.0,1.0,16.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(213,'European, As Muscat, Tokay',1,'1 cup',100.0,1.0,26.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(214,'Grape Juice',1,'1 cup',160.0,1.0,42.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(215,'Lemon Juice',1,'1/2 cup',30.0,0.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(216,'Lemonade Concentratefrozen',1,'6-oz. can',430.0,0.0,112.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(217,'Limeade Concentrate Frozen',1,'6-oz. can',405.0,0.0,108.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(218,'Olives Large',1,'10',72.0,1.0,3.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(219,'Olivesripe',1,'10',105.0,1.0,1.0,13.0,'🍽️',1);
INSERT INTO "foods" VALUES(220,'Oranges 3" Diameter',1,'1 med.',60.0,2.0,16.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(222,'Frozen',1,'6-oz. can',330.0,2.0,78.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(223,'Papaya',1,'1/2 med.',75.0,1.0,18.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(224,'Peaches',1,'1 cup',200.0,1.0,52.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(225,'Pears',1,'1 cup',195.0,1.0,50.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(226,'Raw, 3 By 2V',1,'1 med.',100.0,1.0,25.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(227,'Persimmons',1,'1 med.',75.0,1.0,20.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(228,'Pineapple',1,'1 large slice',95.0,0.0,26.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(229,'Pineapple Crushed',1,'1 cup',205.0,1.0,55.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(230,'Pineapple Juice',1,'1 cup',120.0,1.0,32.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(231,'Plums',1,'1 cup',185.0,1.0,50.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(232,'Raw, 2" Diameter',1,'1',30.0,0.0,7.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(233,'Prunes',1,'1 cup',300.0,3.0,81.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(234,'Prune Juice',1,'1 cup',170.0,1.0,45.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(235,'Raisins',1,'1/2 cup',230.0,2.0,82.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(236,'Raspberries',1,'1/2 cup',100.0,0.0,25.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(237,'Raw, Red',1,'3/4 cup',57.0,0.0,14.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(238,'Rhubarb Sweetened',1,'1 cup',385.0,1.0,98.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(240,'Raw',1,'1 cup',54.0,0.0,12.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(241,'Tangerines',1,'I med.',40.0,1.0,10.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(242,'Watermelon',1,'1 wedge',120.0,2.0,29.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(243,'Biscuits',5,'1',130.0,3.0,18.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(244,'Bran Flakes',5,'1 cup',117.0,3.0,32.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(245,'Bread, Cracked Wheat',5,'1 slice',60.0,2.0,12.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(246,'Rye',5,'1 slice',55.0,2.0,12.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(247,'White, 20 Slices, Or',5,'1-lb. loaf',1225.0,39.0,229.0,15.0,'🍽️',1);
INSERT INTO "foods" VALUES(248,'Whole-Wheat',5,'1-lb. loaf',1100.0,48.0,216.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(249,'Corn Bread Ground Meal',5,'1 serving',100.0,3.0,15.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(250,'Cornflakes',5,'1 cup',110.0,2.0,25.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(251,'Corn Grits Cooked',5,'1 cup',120.0,8.0,27.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(252,'Corn Meal',5,'1 cup',360.0,9.0,74.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(253,'Crackers',5,'2 med.',55.0,1.0,10.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(254,'Soda, 2 1/2 Square',5,'2',45.0,1.0,8.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(255,'Farina',5,'1 cup',105.0,3.0,22.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(256,'Flour',5,'1 cup',460.0,39.0,33.0,22.0,'🍽️',1);
INSERT INTO "foods" VALUES(257,'Wheat (All Purpose)',5,'1 cup',400.0,12.0,84.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(258,'Wheat (Whole)',5,'1 cup',390.0,13.0,79.0,2.0,'🍽️',1);
INSERT INTO "foods" VALUES(259,'Macaroni',5,'1 cup',155.0,5.0,32.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(260,'Baked With Cheese',5,'1 cup',475.0,18.0,44.0,25.0,'🍽️',1);
INSERT INTO "foods" VALUES(261,'Muffins',5,'1',135.0,4.0,19.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(262,'Noodles',5,'1 cup',200.0,7.0,37.0,2.0,'🍽️',1);
INSERT INTO "foods" VALUES(264,'Pancakes 4" Diam.',5,'4',250.0,7.0,28.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(265,'Wheat, Pancakes 4" Diam.',5,'4',250.0,7.0,28.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(266,'Pizza 14" Diam.',5,'1 section',180.0,8.0,23.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(267,'Popcorn Salted',5,'2 cups',152.0,3.0,20.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(268,'Puffed Rice',5,'1 cup',55.0,0.0,12.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(269,'Puffed Wheat Presweetened',5,'1 cup',105.0,1.0,26.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(270,'Rice',5,'1 cup',748.0,15.0,154.0,3.0,'🍽️',1);
INSERT INTO "foods" VALUES(271,'Converted',5,'1 cup',677.0,14.0,142.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(272,'White',5,'1 cup',692.0,14.0,150.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(273,'Rice Flakes',5,'1 cup',115.0,2.0,26.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(274,'Rice Polish',5,'1/2 cup',132.0,6.0,28.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(275,'Rolls',5,'1 large',411.0,3.0,23.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(276,'Of Refined Flour',5,'1',115.0,3.0,20.0,2.0,'🍽️',1);
INSERT INTO "foods" VALUES(277,'Spaghetti With Meat Sauce',5,'1 cup',285.0,13.0,35.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(278,'With Tomatoes And Cheese',5,'1 cup',210.0,6.0,36.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(279,'Spanish Rice',5,'1 cup',217.0,4.0,40.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(280,'Shredded Wheat Biscuit',5,'1',100.0,3.0,23.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(281,'Waffles',5,'1',240.0,8.0,30.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(282,'Wheat Germ',5,'1 cup',245.0,17.0,34.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(283,'Wheat-Germ Cereal Toasted',5,'1 cup',260.0,20.0,36.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(284,'Wheat Meal Cereal Unrefined',5,'3/4 cup',103.0,4.0,25.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(285,'Wheat, Cooked',5,'3/4 cup',275.0,12.0,35.0,1.0,'🍽️',1);
INSERT INTO "foods" VALUES(286,'Apple Betty',3,'1 serving',150.0,1.0,29.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(287,'Bread Pudding',3,'3/4 cup',374.0,11.0,56.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(288,'Cakes',3,'1 slice',110.0,3.0,23.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(289,'Chocolate Fudge',3,'1 slice',420.0,5.0,70.0,14.0,'🍽️',1);
INSERT INTO "foods" VALUES(290,'Cupcake',3,'1',160.0,3.0,31.0,3.0,'🍽️',1);
INSERT INTO "foods" VALUES(291,'Fruit Cake',3,'1 slice',105.0,2.0,17.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(292,'Gingerbread',3,'1 slice',180.0,2.0,28.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(293,'Plain, With No Icing',3,'1 slice',180.0,4.0,31.0,5.0,'🍽️',1);
INSERT INTO "foods" VALUES(294,'Sponge Cake',3,'1 slice',115.0,3.0,22.0,2.0,'🍽️',1);
INSERT INTO "foods" VALUES(295,'Candy',3,'5',104.0,0.0,19.0,3.0,'🍽️',1);
INSERT INTO "foods" VALUES(296,'Chocolate Creams',3,'2',130.0,0.0,24.0,4.0,'🍽️',1);
INSERT INTO "foods" VALUES(297,'Fudge',3,'2 pieces',370.0,0.0,80.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(298,'Hard Candies',3,'1 oz.',90.0,0.0,28.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(299,'Marshmallows',3,'5',98.0,1.0,23.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(300,'Milk Chocolate',3,'2-oz. bar',290.0,2.0,44.0,6.0,'🍽️',1);
INSERT INTO "foods" VALUES(301,'Chocolate Syrup',3,'2 T.',80.0,0.0,22.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(302,'Doughnuts',3,'1',135.0,2.0,17.0,7.0,'🍽️',1);
INSERT INTO "foods" VALUES(303,'Gelatin, Made With Water',3,'1 cup',155.0,4.0,36.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(304,'Honey',3,'2 T.',120.0,0.0,30.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(305,'Ices',3,'1 cup',117.0,0.0,48.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(306,'Preserves',3,'1 T.',55.0,0.0,14.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(307,'Jellies',3,'1 T.',50.0,0.0,13.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(308,'Molasses',3,'1 T.',45.0,0.0,11.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(309,'Cane Syrup',3,'1 T.',50.0,0.0,13.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(310,'9" Diam. Pie',3,'1 slice',330.0,3.0,53.0,13.0,'🍽️',1);
INSERT INTO "foods" VALUES(311,'Cherry Pie',3,'1 slice',340.0,3.0,55.0,13.0,'🍽️',1);
INSERT INTO "foods" VALUES(312,'Lemon Meringue',3,'1 slice',300.0,4.0,45.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(313,'Mince',3,'1 slice',340.0,3.0,62.0,9.0,'🍽️',1);
INSERT INTO "foods" VALUES(314,'Pumpkin Pie',3,'1 slice',265.0,5.0,34.0,12.0,'🍽️',1);
INSERT INTO "foods" VALUES(315,'Puddings Sugar',3,'1 cup',770.0,0.0,199.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(316,'3 Teaspoons Sugar',3,'1 T.',50.0,0.0,12.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(317,'Brown, Firm-Packed, Dark Sugar',3,'1 cup',815.0,0.0,210.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(318,'Syrup',3,'2 T.',100.0,0.0,25.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(319,'Table Blends Sugar',3,'2 T.',110.0,0.0,29.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(320,'Tapioca Cream Pudding',3,'1 cup',335.0,10.0,42.0,10.0,'🍽️',1);
INSERT INTO "foods" VALUES(322,'Roasted And Salted',7,'1/2 cup',439.0,13.0,13.0,40.0,'🍽️',1);
INSERT INTO "foods" VALUES(323,'Brazil Nuts',7,'1/2 cup',457.0,10.0,7.0,47.0,'🍽️',1);
INSERT INTO "foods" VALUES(324,'Cashews',7,'1/2 cup',392.0,12.0,20.0,32.0,'🍽️',1);
INSERT INTO "foods" VALUES(325,'Coconut Sweetened',7,'1/2 cup',274.0,1.0,26.0,20.0,'🍽️',1);
INSERT INTO "foods" VALUES(327,'Peanut Butter, Natural',7,'1/3 cup',284.0,13.0,8.0,24.0,'🍽️',1);
INSERT INTO "foods" VALUES(328,'Peanuts',7,'1/3 cup',290.0,13.0,9.0,25.0,'🍽️',1);
INSERT INTO "foods" VALUES(329,'Pecans',7,'1/2 cup',343.0,5.0,7.0,35.0,'🍽️',1);
INSERT INTO "foods" VALUES(330,'Sesame Seeds',7,'1/2 cup',280.0,9.0,10.0,24.0,'🍽️',1);
INSERT INTO "foods" VALUES(331,'Sunflower Seeds',7,'1/2 cup',280.0,12.0,10.0,26.0,'🍽️',1);
INSERT INTO "foods" VALUES(332,'Walnuts',7,'1/2 cup',325.0,7.0,8.0,32.0,'🍽️',1);
INSERT INTO "foods" VALUES(333,'Beer',9,'2 cups',228.0,0.0,8.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(334,'Gin',9,'1 oz.',70.0,0.0,0.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(335,'Wines',9,'1/2 cup',164.0,0.0,9.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(336,'Table (12.2% Alcohol)',9,'1/2 cup',100.0,0.0,5.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(337,'Carbonated Drinks Artificially Sweetened',9,'12 oz.',0.0,0.0,0.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(338,'Club Soda',9,'12 oz.',0.0,0.0,0.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(339,'Cola Drinks',9,'12 oz.',137.0,0.0,38.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(340,'Fruit-Flavored Soda',9,'12 oz.',161.0,0.0,42.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(341,'Ginger Ale',9,'12 oz.',105.0,0.0,28.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(342,'Root Beer',9,'12 oz.',140.0,0.0,35.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(343,'Coffee',9,'1 cup',3.0,0.0,1.0,0.0,'🍽️',1);
INSERT INTO "foods" VALUES(344,'Tea',9,'1 cup',4.0,0.0,1.0,0.0,'🍽️',1);
CREATE TABLE goal_history (
    history_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    record_type TEXT NOT NULL CHECK (record_type IN ('manual', 'estimate')),
    record_date TEXT NOT NULL,
    record_time TEXT NOT NULL,
    calories    REAL NOT NULL,
    protein     REAL NOT NULL,
    carbs       REAL NOT NULL,
    fat         REAL NOT NULL,
    applied     INTEGER NOT NULL DEFAULT 0 CHECK (applied IN (0, 1)),
    profile_text TEXT,
    saved_at    TEXT NOT NULL
);
CREATE TABLE goals (
    goal_id  INTEGER PRIMARY KEY CHECK (goal_id = 1),
    calories REAL NOT NULL CHECK (calories > 0),
    protein  REAL NOT NULL CHECK (protein  > 0),
    carbs    REAL NOT NULL CHECK (carbs    > 0),
    fat      REAL NOT NULL CHECK (fat      > 0)
);
INSERT INTO "goals" VALUES(1,2000.0,100.0,250.0,65.0);
CREATE INDEX idx_entries_date ON entries(entry_date);
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('food_groups',10);
INSERT INTO "sqlite_sequence" VALUES('foods',346);
INSERT INTO "sqlite_sequence" VALUES('entries',10);
COMMIT;
