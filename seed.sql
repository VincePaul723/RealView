-- RealView dummy data. Run AFTER schema.sql:
--   mysql -u <user> -p realview < seed.sql
-- Password hashes are bcrypt of "password123" (placeholder; replace when auth is wired up).

USE realview;

-- Users --------------------------------------------------------
INSERT INTO users (user_id, username, email, password_hash) VALUES
(1, 'vince',  'vince@realview.test', '$2b$10$placeholderhashplaceholderhashplaceholderhashpl'),
(2, 'dad',    'dad@realview.test',   '$2b$10$placeholderhashplaceholderhashplaceholderhashpl'),
(3, 'marcus', 'marcus@realview.test','$2b$10$placeholderhashplaceholderhashplaceholderhashpl');

-- Properties ---------------------------------------------------
INSERT INTO properties
(property_id, user_id, status, street, city, state, zip, bedrooms, bathrooms, sqft, year_built,
 asking_price, arv, repair_estimate, max_offer, purchase_price, purchase_date, repair_budget,
 sale_price, sale_date, source, listing_url, external_id, listing_photo_url, saved_at, notes) VALUES
-- prospects
(1, 1, 'prospect', '1427 Maple Ridge Dr', 'Decatur', 'GA', '30032', 3, 2.0, 1450, 1968,
 165000, 265000, 42000, 140000, NULL, NULL, NULL, NULL, NULL,
 'search', 'https://example-listings.test/l/GA-88213', 'GA-88213', 'https://example-listings.test/img/GA-88213.jpg', '2026-10-02 14:10:00',
 'Brick ranch, needs roof and kitchen. Seller motivated.'),
(2, 1, 'prospect', '88 Pinehurst Ct', 'Stone Mountain', 'GA', '30083', 4, 2.5, 2100, 1994,
 230000, 340000, 55000, 180000, NULL, NULL, NULL, NULL, NULL,
 'manual', NULL, NULL, NULL, NULL,
 'Found through wholesaler. Foundation looks fine, HVAC dead.'),
(3, 1, 'prospect', '2210 Glenwood Ave SE', 'Atlanta', 'GA', '30316', 2, 1.0, 980, 1952,
 199000, 310000, 60000, 150000, NULL, NULL, NULL, NULL, NULL,
 'search', 'https://example-listings.test/l/GA-90114', 'GA-90114', 'https://example-listings.test/img/GA-90114.jpg', '2026-10-11 09:35:00',
 'East Atlanta. Small but the area is hot.'),
-- owned
(4, 1, 'owned', '615 Oakdale Rd', 'Lithonia', 'GA', '30058', 3, 2.0, 1620, 1985,
 142000, 240000, 38000, 125000, 128000, '2026-07-15', 40000, NULL, NULL,
 'manual', NULL, NULL, NULL, NULL,
 'First flip of the year. Target list date mid November.'),
(5, 2, 'owned', '3301 Candler Rd', 'Decatur', 'GA', '30034', 4, 2.0, 1890, 1978,
 175000, 290000, 50000, 150000, 158000, '2026-05-02', 55000, NULL, NULL,
 'manual', NULL, NULL, NULL, NULL,
 'Dad''s project. Full cosmetic rehab plus new roof.'),
-- sold
(6, 1, 'sold', '940 Flat Shoals Pkwy', 'Decatur', 'GA', '30034', 3, 1.5, 1300, 1972,
 120000, 215000, 30000, 110000, 112000, '2026-01-20', 32000, 218000, '2026-06-28',
 'manual', NULL, NULL, NULL, NULL,
 'Closed. Sold above ARV.');

-- Payroll ------------------------------------------------------
INSERT INTO payroll (property_id, worker_name, role, hours_worked, hourly_rate, amount_paid, pay_date, notes) VALUES
(4, 'Luis Ramirez',  'General labor', 40.0, 22.00,  880.00, '2026-08-01', NULL),
(4, 'Luis Ramirez',  'General labor', 38.5, 22.00,  847.00, '2026-08-15', NULL),
(4, 'Tony Blake',    'Electrician',   16.0, 55.00,  880.00, '2026-08-20', 'Panel upgrade'),
(4, 'Luis Ramirez',  'General labor', 40.0, 22.00,  880.00, '2026-09-01', NULL),
(5, 'Derrick Hall',  'GC',            NULL, NULL,  4500.00, '2026-06-01', 'Draw 1 of 3'),
(5, 'Derrick Hall',  'GC',            NULL, NULL,  4500.00, '2026-07-15', 'Draw 2 of 3'),
(5, 'Jamal Reed',    'Painter',       32.0, 25.00,  800.00, '2026-08-10', NULL),
(6, 'Luis Ramirez',  'General labor', 80.0, 20.00, 1600.00, '2026-02-28', NULL),
(6, 'Tony Blake',    'Electrician',   10.0, 55.00,  550.00, '2026-03-05', NULL);

-- Repair costs -------------------------------------------------
INSERT INTO repair_costs (property_id, category, description, vendor, cost, expense_date, receipt_url) VALUES
(4, 'Roof',       'Full tear-off and shingle replacement', 'Peachtree Roofing', 9800.00, '2026-07-28', NULL),
(4, 'Kitchen',    'Cabinets and countertops',               'Home Depot',       6200.00, '2026-08-12', NULL),
(4, 'Plumbing',   'Replace water heater',                   'Lowe''s',           1150.00, '2026-08-18', NULL),
(4, 'Paint',      'Interior paint, 15 gal',                 'Sherwin-Williams',  640.00, '2026-09-03', NULL),
(4, 'Permits',    'Electrical permit',                      'DeKalb County',     185.00, '2026-08-19', NULL),
(5, 'Roof',       'Roof replacement',                       'Peachtree Roofing',11400.00,'2026-05-20', NULL),
(5, 'Flooring',   'LVP throughout',                         'Floor & Decor',    5300.00, '2026-07-02', NULL),
(5, 'Bathroom',   'Tile, vanity, fixtures x2',              'Home Depot',       4100.00, '2026-07-30', NULL),
(5, 'HVAC',       'New 3-ton unit',                         'Cool Air Services',6800.00, '2026-08-05', NULL),
(6, 'Kitchen',    'Cabinet refacing and counters',          'Home Depot',       4900.00, '2026-02-15', NULL),
(6, 'Flooring',   'Refinish hardwoods',                     'ATL Floor Pros',   2800.00, '2026-03-01', NULL),
(6, 'Paint',      'Interior and exterior paint',            'Sherwin-Williams', 1100.00, '2026-03-10', NULL),
(6, 'Landscaping','Clean-up and sod',                       'Green Thumb LLC',   950.00, '2026-04-01', NULL);

-- Toolboxes ----------------------------------------------------
INSERT INTO toolboxes (toolbox_id, user_id, property_id, box_name, description, moved_on) VALUES
(1, 1, 4,    'Red Milwaukee box',  'Main power tools',          '2026-07-20'),
(2, 1, 4,    'Plumbing kit',       'Blue tote',                 '2026-08-16'),
(3, 1, NULL, 'Truck box',          'Stays in the truck',        NULL),
(4, 2, 5,    'Dad''s big box',     'Husky rolling chest',       '2026-05-10');

-- Tools --------------------------------------------------------
INSERT INTO tools (user_id, toolbox_id, tool_name, quantity, serial_number, condition_note) VALUES
(1, 1, 'Milwaukee M18 drill',        2, 'MW-2804-1193', 'Good'),
(1, 1, 'Milwaukee circular saw',     1, 'MW-2730-0442', 'Blade needs replacing'),
(1, 1, 'Impact driver',              1, 'MW-2853-7781', 'Good'),
(1, 1, 'Battery packs 5Ah',          4, NULL,           'One holds weak charge'),
(1, 2, 'Pipe wrench 14in',           1, NULL,           'Good'),
(1, 2, 'PEX crimp tool',             1, NULL,           'Good'),
(1, 2, 'Torch kit',                  1, NULL,           'Low propane'),
(1, 3, 'Tape measure',               3, NULL,           'Good'),
(1, 3, 'Level 4ft',                  1, NULL,           'Good'),
(1, NULL, 'Shop vac',                1, NULL,           'Loose, in garage'),
(2, 4, 'DeWalt drill',               1, 'DW-996-2201',  'Good'),
(2, 4, 'Miter saw',                  1, 'DW-779-8840',  'Good'),
(2, 4, 'Nail gun',                   1, NULL,           'Needs oil');

-- Saved searches -----------------------------------------------
INSERT INTO saved_searches (user_id, search_name, city, state, zip, min_price, max_price, min_bedrooms) VALUES
(1, 'Decatur under 200k',   'Decatur', 'GA', NULL,    NULL,   200000, 3),
(1, 'East Atlanta 30316',   NULL,      'GA', '30316', 100000, 250000, 2),
(2, 'South DeKalb 4 beds',  NULL,      'GA', '30034', NULL,   220000, 4);

-- Property notes -----------------------------------------------
INSERT INTO property_notes (property_id, user_id, note_text, created_at) VALUES
(1, 1, 'Called listing agent, seller will consider cash offers under asking.',          '2026-10-03 10:15:00'),
(1, 1, 'Drove by. Roof is worse than photos, budget 12k not 8k.',                        '2026-10-05 17:40:00'),
(2, 1, 'Wholesaler wants 5k assignment fee. Contract expires 10/30.',                   '2026-10-08 12:00:00'),
(3, 1, 'Comps at 300k+ on the same street. Worth a lowball.',                            '2026-10-11 09:50:00'),
(4, 1, 'Roof done. Kitchen cabinets arrive 8/12.',                                       '2026-08-01 08:00:00'),
(4, 1, 'Electrical passed inspection.',                                                  '2026-08-27 15:30:00'),
(5, 2, 'HVAC installed. Painter starts next week.',                                      '2026-08-06 18:00:00');

-- Property contacts --------------------------------------------
INSERT INTO property_contacts (property_id, contact_name, role, company, phone, email, notes) VALUES
(1, 'Karen Whitfield', 'Listing agent', 'Keller Williams Decatur', '404-555-0142', 'karen.w@example.test', 'Responds fast by text'),
(1, 'R. Thompson',     'Seller',        NULL,                       NULL,           NULL,                   'Estate sale, out of state'),
(2, 'Mike Oduya',      'Wholesaler',    'ATL Deal Flow',            '678-555-0199', 'mike@example.test',    NULL),
(3, 'Priya Nair',      'Listing agent', 'Compass',                  '404-555-0177', 'priya.n@example.test', NULL),
(4, 'Tony Blake',      'Electrician',   'Blake Electric',           '770-555-0120', NULL,                   'Licensed, DeKalb'),
(4, 'Sam Ortiz',       'Lender',        'Peach State Capital',      '404-555-0188', 'sam@example.test',     'Hard money, 12 month term'),
(5, 'Derrick Hall',    'GC',            'Hall Construction',        '678-555-0133', 'derrick@example.test', NULL);

-- Photos -------------------------------------------------------
INSERT INTO property_photos (property_id, photo_url, caption, stage, taken_on) VALUES
(4, '/uploads/oakdale/before-kitchen.jpg', 'Kitchen before',        'before', '2026-07-16'),
(4, '/uploads/oakdale/roof-progress.jpg',  'New roof going on',     'during', '2026-07-27'),
(4, '/uploads/oakdale/kitchen-after.jpg',  'Kitchen after cabinets','during', '2026-08-30'),
(5, '/uploads/candler/before-front.jpg',   'Curb appeal before',    'before', '2026-05-03'),
(6, '/uploads/flatshoals/after-front.jpg', 'Listing photo',         'listing','2026-04-10');

-- Milestones ---------------------------------------------------
INSERT INTO milestones (property_id, title, target_date, completed_on, sort_order) VALUES
(4, 'Closing',          '2026-07-15', '2026-07-15', 1),
(4, 'Demo',             '2026-07-22', '2026-07-24', 2),
(4, 'Roof',             '2026-07-30', '2026-07-28', 3),
(4, 'Kitchen',          '2026-08-20', '2026-08-30', 4),
(4, 'Paint and floors', '2026-09-20', NULL,         5),
(4, 'List for sale',    '2026-11-15', NULL,         6),
(5, 'Closing',          '2026-05-02', '2026-05-02', 1),
(5, 'Roof',             '2026-05-25', '2026-05-20', 2),
(5, 'HVAC',             '2026-08-01', '2026-08-05', 3),
(5, 'Paint',            '2026-08-20', NULL,         4),
(5, 'List for sale',    '2026-10-01', NULL,         5),
(6, 'Closing',          '2026-01-20', '2026-01-20', 1),
(6, 'List for sale',    '2026-04-15', '2026-04-12', 2),
(6, 'Sold',             '2026-06-30', '2026-06-28', 3);

-- Comps --------------------------------------------------------
INSERT INTO comps (property_id, street, city, sold_price, sold_date, bedrooms, bathrooms, sqft, distance_mi, source_url) VALUES
(1, '1502 Maple Ridge Dr', 'Decatur', 262000, '2026-08-14', 3, 2.0, 1400, 0.10, NULL),
(1, '1388 Columbia Dr',    'Decatur', 271000, '2026-07-02', 3, 2.0, 1520, 0.45, NULL),
(2, '102 Pinehurst Ct',    'Stone Mountain', 335000, '2026-09-01', 4, 2.5, 2050, 0.05, NULL),
(3, '2240 Glenwood Ave SE','Atlanta', 318000, '2026-09-20', 2, 1.0, 1010, 0.08, NULL),
(3, '1180 Bouldercrest Dr','Atlanta', 299000, '2026-08-05', 3, 1.0, 1100, 0.70, NULL);

-- Documents ----------------------------------------------------
INSERT INTO property_documents (property_id, doc_name, doc_type, file_url) VALUES
(4, 'Purchase contract',      'contract',   '/docs/oakdale/contract.pdf'),
(4, 'Inspection report',      'inspection', '/docs/oakdale/inspection.pdf'),
(4, 'Hard money term sheet',  'closing',    '/docs/oakdale/loan-terms.pdf'),
(5, 'Purchase contract',      'contract',   '/docs/candler/contract.pdf'),
(6, 'Closing statement',      'closing',    '/docs/flatshoals/closing.pdf');

-- Property members (sharing) -----------------------------------
INSERT INTO property_members (property_id, user_id, access_level) VALUES
(4, 2, 'viewer'),   -- dad can view Vince's Oakdale flip
(4, 3, 'editor'),   -- marcus (partner) can edit it
(5, 1, 'editor');   -- vince can edit dad's Candler project

-- Activity log -------------------------------------------------
INSERT INTO activity_log (user_id, property_id, action, summary, created_at) VALUES
(1, 1, 'property_saved',  'Saved 1427 Maple Ridge Dr from search',          '2026-10-02 14:10:00'),
(1, 1, 'note_added',      'Added a note on 1427 Maple Ridge Dr',             '2026-10-03 10:15:00'),
(1, 4, 'expense_added',   'Added $640 paint expense at 615 Oakdale Rd',      '2026-09-03 16:20:00'),
(1, 4, 'payroll_added',   'Paid Luis Ramirez $880 at 615 Oakdale Rd',        '2026-09-01 17:00:00'),
(1, 3, 'property_saved',  'Saved 2210 Glenwood Ave SE from search',          '2026-10-11 09:35:00'),
(2, 5, 'milestone_done',  'Completed HVAC at 3301 Candler Rd',               '2026-08-05 15:00:00'),
(1, 6, 'status_changed',  '940 Flat Shoals Pkwy marked sold',                '2026-06-28 12:00:00');
