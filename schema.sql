-- RealView: property tracker for real estate investors
-- MySQL 8 schema outline. Run with:  mysql -u <user> -p < schema.sql

DROP DATABASE IF EXISTS realview;   -- start clean every time (dev only!)
CREATE DATABASE realview;
USE realview;

-- ---------------------------------------------------------------
-- 1. Users (basic authentication)
-- ---------------------------------------------------------------
CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    username       VARCHAR(50)  NOT NULL UNIQUE,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,          -- store a bcrypt hash, never the raw password
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------
-- 2. Properties
--    One table for both kinds. `status` says which:
--      'prospect' = a house the investor is looking at buying
--      'owned'    = a house the investor has purchased
--    A prospect becomes owned by updating status + purchase fields.
-- ---------------------------------------------------------------
CREATE TABLE properties (
    property_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    status          ENUM('prospect', 'owned', 'sold') NOT NULL DEFAULT 'prospect',

    -- address
    street          VARCHAR(255) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           CHAR(2)      NOT NULL,
    zip             VARCHAR(10)  NOT NULL,

    -- basic facts
    bedrooms        TINYINT UNSIGNED,
    bathrooms       DECIMAL(3,1),
    sqft            INT UNSIGNED,
    year_built      SMALLINT UNSIGNED,

    -- deal numbers (filled in while it's a prospect)
    asking_price    DECIMAL(12,2),
    arv             DECIMAL(12,2),                 -- after repair value
    repair_estimate DECIMAL(12,2),
    max_offer       DECIMAL(12,2),                 -- what the investor is willing to pay

    -- purchase info (filled in once it's owned)
    purchase_price  DECIMAL(12,2),
    purchase_date   DATE,
    repair_budget   DECIMAL(12,2),                 -- planned rehab spend; compare to payroll + repair_costs

    -- exit info (filled in once it's sold)
    sale_price      DECIMAL(12,2),
    sale_date       DATE,

    -- where the record came from
    --   'manual' = typed in by the user
    --   'search' = saved from a property search on the website
    source          ENUM('manual', 'search') NOT NULL DEFAULT 'manual',
    listing_url     VARCHAR(500),                  -- link back to the listing it was saved from
    external_id     VARCHAR(100),                  -- the listing's id in the search source (MLS #, API id...)
    listing_photo_url VARCHAR(500),
    saved_at        TIMESTAMP NULL,                -- when it was saved from search

    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY uq_user_listing (user_id, external_id)   -- same listing can't be saved twice by one user
);

-- ---------------------------------------------------------------
-- 3. Payroll per property (owned properties)
--    One row per worker per pay period.
-- ---------------------------------------------------------------
CREATE TABLE payroll (
    payroll_id    INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    worker_name   VARCHAR(100) NOT NULL,
    role          VARCHAR(100),                     -- e.g. plumber, GC, laborer
    hours_worked  DECIMAL(6,2),
    hourly_rate   DECIMAL(8,2),
    amount_paid   DECIMAL(10,2) NOT NULL,
    pay_date      DATE NOT NULL,
    notes         TEXT,

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 4. Repair costs per property
--    Materials, contractor invoices, permits, etc.
-- ---------------------------------------------------------------
CREATE TABLE repair_costs (
    repair_id     INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    category      VARCHAR(100) NOT NULL,            -- roof, plumbing, electrical, paint...
    description   VARCHAR(255),
    vendor        VARCHAR(100),
    cost          DECIMAL(10,2) NOT NULL,
    expense_date  DATE NOT NULL,
    receipt_url   VARCHAR(500),

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 5. Toolboxes
--    A toolbox lives at one property (NULL = in storage / the truck).
--    Tools go inside toolboxes, so "tools at this property" =
--    every tool in every toolbox whose property_id matches.
-- ---------------------------------------------------------------
CREATE TABLE toolboxes (
    toolbox_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    property_id   INT NULL,
    box_name      VARCHAR(100) NOT NULL,            -- "Red Milwaukee box", "Plumbing kit"
    description   VARCHAR(255),
    moved_on      DATE,                             -- when it arrived at the current property
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)     REFERENCES users(user_id)           ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id)  ON DELETE SET NULL
);

-- ---------------------------------------------------------------
-- 6. Tools
--    Every tool belongs to the user and sits in one toolbox
--    (NULL toolbox = loose / unassigned).
-- ---------------------------------------------------------------
CREATE TABLE tools (
    tool_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    toolbox_id     INT NULL,
    tool_name      VARCHAR(100) NOT NULL,
    quantity       INT UNSIGNED NOT NULL DEFAULT 1,
    serial_number  VARCHAR(100),
    condition_note VARCHAR(255),

    FOREIGN KEY (user_id)    REFERENCES users(user_id)        ON DELETE CASCADE,
    FOREIGN KEY (toolbox_id) REFERENCES toolboxes(toolbox_id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------
-- 7. Saved searches (optional)
--    Lets a user keep the search criteria they used on the site
--    so they can rerun it later.
-- ---------------------------------------------------------------
CREATE TABLE saved_searches (
    search_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    search_name   VARCHAR(100),
    city          VARCHAR(100),
    state         CHAR(2),
    zip           VARCHAR(10),
    min_price     DECIMAL(12,2),
    max_price     DECIMAL(12,2),
    min_bedrooms  TINYINT UNSIGNED,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 8. Property notes
--    Many notes per property, each timestamped, so a user can keep a
--    running log on a saved listing ("called agent", "drove by", ...).
--    properties.notes stays as a one-line summary; this is the history.
-- ---------------------------------------------------------------
CREATE TABLE property_notes (
    note_id       INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    user_id       INT NOT NULL,                     -- who wrote it
    note_text     TEXT NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)     REFERENCES users(user_id)          ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 9. Property contacts
--    People attached to a property: listing agent, seller, wholesaler,
--    contractor, lender, etc.
-- ---------------------------------------------------------------
CREATE TABLE property_contacts (
    contact_id    INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    contact_name  VARCHAR(100) NOT NULL,
    role          VARCHAR(50),                      -- agent, seller, wholesaler, contractor, lender...
    company       VARCHAR(100),
    phone         VARCHAR(30),
    email         VARCHAR(255),
    notes         VARCHAR(255),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 10. Property photos
--     Before/after and progress shots. Files live on disk or S3;
--     the DB only stores the path/URL.
-- ---------------------------------------------------------------
CREATE TABLE property_photos (
    photo_id      INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    photo_url     VARCHAR(500) NOT NULL,
    caption       VARCHAR(255),
    stage         ENUM('before', 'during', 'after', 'listing') NOT NULL DEFAULT 'during',
    taken_on      DATE,
    uploaded_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 11. Milestones (project timeline for owned properties)
-- ---------------------------------------------------------------
CREATE TABLE milestones (
    milestone_id  INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    title         VARCHAR(100) NOT NULL,            -- closing, demo, rough-in, inspection, listed, sold...
    target_date   DATE,
    completed_on  DATE,                             -- NULL = not done yet
    sort_order    INT NOT NULL DEFAULT 0,
    notes         VARCHAR(255),

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 12. Comparables (comps) that justify a prospect's ARV
-- ---------------------------------------------------------------
CREATE TABLE comps (
    comp_id       INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    street        VARCHAR(255) NOT NULL,
    city          VARCHAR(100),
    sold_price    DECIMAL(12,2) NOT NULL,
    sold_date     DATE,
    bedrooms      TINYINT UNSIGNED,
    bathrooms     DECIMAL(3,1),
    sqft          INT UNSIGNED,
    distance_mi   DECIMAL(4,2),
    source_url    VARCHAR(500),

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 13. Documents (contracts, inspections, receipts, closing docs)
-- ---------------------------------------------------------------
CREATE TABLE property_documents (
    document_id   INT AUTO_INCREMENT PRIMARY KEY,
    property_id   INT NOT NULL,
    doc_name      VARCHAR(150) NOT NULL,
    doc_type      VARCHAR(50),                      -- contract, inspection, receipt, insurance, closing...
    file_url      VARCHAR(500) NOT NULL,
    uploaded_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 14. Property members (sharing)
--     Let the owner invite a partner or contractor to one property.
--     The owner is implied by properties.user_id and is not listed here.
-- ---------------------------------------------------------------
CREATE TABLE property_members (
    property_id   INT NOT NULL,
    user_id       INT NOT NULL,
    access_level  ENUM('viewer', 'editor') NOT NULL DEFAULT 'viewer',
    added_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (property_id, user_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)     REFERENCES users(user_id)          ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- 15. Activity log (feeds the dashboard "recent activity")
--     Insert a row from the app whenever something notable happens.
-- ---------------------------------------------------------------
CREATE TABLE activity_log (
    activity_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    property_id   INT NULL,
    action        VARCHAR(50) NOT NULL,             -- note_added, expense_added, payroll_added, status_changed...
    summary       VARCHAR(255) NOT NULL,            -- "Added $1,200 roofing expense"
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)     REFERENCES users(user_id)          ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------
-- Helpful indexes
-- ---------------------------------------------------------------
CREATE INDEX idx_properties_user_status ON properties(user_id, status);
CREATE INDEX idx_payroll_property       ON payroll(property_id, pay_date);
CREATE INDEX idx_repairs_property       ON repair_costs(property_id, expense_date);
CREATE INDEX idx_toolboxes_property     ON toolboxes(property_id);
CREATE INDEX idx_tools_toolbox          ON tools(toolbox_id);
CREATE INDEX idx_notes_property         ON property_notes(property_id, created_at);
CREATE INDEX idx_contacts_property      ON property_contacts(property_id);
CREATE INDEX idx_photos_property        ON property_photos(property_id);
CREATE INDEX idx_milestones_property    ON milestones(property_id, sort_order);
CREATE INDEX idx_comps_property         ON comps(property_id);
CREATE INDEX idx_documents_property     ON property_documents(property_id);
CREATE INDEX idx_activity_user          ON activity_log(user_id, created_at);

-- ---------------------------------------------------------------
-- Starter queries the site will need
-- ---------------------------------------------------------------

-- All prospects for a logged-in user, with a quick spread estimate
-- SELECT property_id, street, city, asking_price, arv, repair_estimate,
--        arv - repair_estimate - asking_price AS rough_spread
-- FROM properties
-- WHERE user_id = ? AND status = 'prospect';

-- Total spent on an owned property (payroll + repairs)
-- SELECT p.property_id, p.street,
--        (SELECT COALESCE(SUM(amount_paid),0) FROM payroll      WHERE property_id = p.property_id) AS payroll_total,
--        (SELECT COALESCE(SUM(cost),0)        FROM repair_costs WHERE property_id = p.property_id) AS repair_total
-- FROM properties p
-- WHERE p.property_id = ?;

-- Toolboxes and their tools currently at a property
-- SELECT tb.box_name, t.tool_name, t.quantity
-- FROM toolboxes tb
-- LEFT JOIN tools t ON t.toolbox_id = tb.toolbox_id
-- WHERE tb.property_id = ?
-- ORDER BY tb.box_name, t.tool_name;

-- Move a toolbox (and everything in it) to another property
-- UPDATE toolboxes SET property_id = ?, moved_on = CURDATE() WHERE toolbox_id = ?;

-- Save a property found through the website's search as a prospect
-- INSERT INTO properties (user_id, status, street, city, state, zip, bedrooms, bathrooms, sqft,
--                         asking_price, source, listing_url, external_id, listing_photo_url, saved_at)
-- VALUES (?, 'prospect', ?, ?, ?, ?, ?, ?, ?, ?, 'search', ?, ?, ?, NOW());

-- Notes on a property, newest first
-- SELECT note_text, created_at FROM property_notes WHERE property_id = ? ORDER BY created_at DESC;

-- Contacts for a property
-- SELECT contact_name, role, phone, email FROM property_contacts WHERE property_id = ?;

-- ---------------------------------------------------------------
-- Deal calculator (one query, no new tables)
--   MAO = max allowable offer by the 70% rule
-- ---------------------------------------------------------------
-- SELECT property_id, street, arv, repair_estimate, asking_price,
--        ROUND(arv * 0.70 - repair_estimate, 2)                       AS mao_70_rule,
--        ROUND(arv - asking_price - repair_estimate, 2)               AS projected_profit,
--        ROUND((arv - asking_price - repair_estimate)
--              / NULLIF(asking_price + repair_estimate, 0) * 100, 1)  AS roi_pct
-- FROM properties
-- WHERE user_id = ? AND status = 'prospect';

-- Budget vs actual for an owned property
-- (subqueries, not joins: joining payroll and repairs together multiplies rows)
-- SELECT p.street, p.repair_budget,
--        (SELECT COALESCE(SUM(amount_paid),0) FROM payroll      WHERE property_id = p.property_id) AS payroll_total,
--        (SELECT COALESCE(SUM(cost),0)        FROM repair_costs WHERE property_id = p.property_id) AS repair_total,
--        p.repair_budget
--          - (SELECT COALESCE(SUM(amount_paid),0) FROM payroll      WHERE property_id = p.property_id)
--          - (SELECT COALESCE(SUM(cost),0)        FROM repair_costs WHERE property_id = p.property_id) AS remaining
-- FROM properties p
-- WHERE p.property_id = ?;

-- Final profit on sold deals (track record)
-- SELECT p.street, p.purchase_price, p.sale_price,
--        (SELECT COALESCE(SUM(amount_paid),0) FROM payroll      WHERE property_id = p.property_id) AS payroll_total,
--        (SELECT COALESCE(SUM(cost),0)        FROM repair_costs WHERE property_id = p.property_id) AS repair_total,
--        p.sale_price - p.purchase_price
--          - (SELECT COALESCE(SUM(amount_paid),0) FROM payroll      WHERE property_id = p.property_id)
--          - (SELECT COALESCE(SUM(cost),0)        FROM repair_costs WHERE property_id = p.property_id) AS net_profit
-- FROM properties p
-- WHERE p.user_id = ? AND p.status = 'sold';

-- Recent activity for the dashboard
-- SELECT a.summary, a.created_at, p.street
-- FROM activity_log a LEFT JOIN properties p ON p.property_id = a.property_id
-- WHERE a.user_id = ? ORDER BY a.created_at DESC LIMIT 20;
