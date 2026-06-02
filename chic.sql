-- Base de données pour Chicago Burger - Gestion des stocks
-- Création de la base de données
CREATE DATABASE chicago_burger_stock;
USE chicago_burger_stock;

-- Table des catégories de produits
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des fournisseurs
CREATE TABLE fournisseurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(150) NOT NULL,
    contact_nom VARCHAR(100),
    telephone VARCHAR(20),
    email VARCHAR(100),
    adresse TEXT,
    ville VARCHAR(50),
    code_postal VARCHAR(10),
    pays VARCHAR(50) DEFAULT 'France',
    conditions_paiement VARCHAR(50),
    delai_livraison INT, -- en jours
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des unités de mesure
CREATE TABLE unites_mesure (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(20) NOT NULL UNIQUE, -- kg, g, L, ml, pièce, etc.
    abreviation VARCHAR(10) NOT NULL UNIQUE
);

-- Table des produits/ingrédients
CREATE TABLE produits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(150) NOT NULL,
    code_produit VARCHAR(50) UNIQUE,
    categorie_id INT,
    fournisseur_id INT,
    unite_mesure_id INT,
    prix_unitaire DECIMAL(10,2),
    stock_actuel DECIMAL(10,2) DEFAULT 0,
    stock_minimum DECIMAL(10,2) DEFAULT 0,
    stock_maximum DECIMAL(10,2),
    date_expiration DATE,
    lot_numero VARCHAR(50),
    emplacement_stockage VARCHAR(100),
    temperature_stockage ENUM('ambiant', 'refrigere', 'congele'),
    actif BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (categorie_id) REFERENCES categories(id),
    FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id),
    FOREIGN KEY (unite_mesure_id) REFERENCES unites_mesure(id)
);

-- Table des mouvements de stock
CREATE TABLE mouvements_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produit_id INT NOT NULL,
    type_mouvement ENUM('entree', 'sortie', 'ajustement', 'perte') NOT NULL,
    quantite DECIMAL(10,2) NOT NULL,
    stock_avant DECIMAL(10,2) NOT NULL,
    stock_apres DECIMAL(10,2) NOT NULL,
    prix_unitaire DECIMAL(10,2),
    valeur_totale DECIMAL(10,2),
    motif VARCHAR(200),
    numero_facture VARCHAR(50),
    utilisateur VARCHAR(100),
    date_mouvement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Table des commandes fournisseurs
CREATE TABLE commandes_fournisseurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    numero_commande VARCHAR(50) UNIQUE NOT NULL,
    fournisseur_id INT NOT NULL,
    date_commande DATE NOT NULL,
    date_livraison_prevue DATE,
    date_livraison_reelle DATE,
    statut ENUM('en_attente', 'confirmee', 'expediee', 'livree', 'annulee') DEFAULT 'en_attente',
    montant_total DECIMAL(12,2),
    tva DECIMAL(12,2),
    montant_ttc DECIMAL(12,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fournisseur_id) REFERENCES fournisseurs(id)
);

-- Table des détails des commandes fournisseurs
CREATE TABLE details_commandes_fournisseurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    commande_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite_commandee DECIMAL(10,2) NOT NULL,
    quantite_livree DECIMAL(10,2) DEFAULT 0,
    prix_unitaire DECIMAL(10,2) NOT NULL,
    montant_ligne DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (commande_id) REFERENCES commandes_fournisseurs(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Table des inventaires
CREATE TABLE inventaires (
    id INT PRIMARY KEY AUTO_INCREMENT,
    date_inventaire DATE NOT NULL,
    type_inventaire ENUM('complet', 'partiel', 'cyclique') NOT NULL,
    statut ENUM('en_cours', 'termine', 'valide') DEFAULT 'en_cours',
    responsable VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des détails d'inventaire
CREATE TABLE details_inventaires (
    id INT PRIMARY KEY AUTO_INCREMENT,
    inventaire_id INT NOT NULL,
    produit_id INT NOT NULL,
    stock_theorique DECIMAL(10,2) NOT NULL,
    stock_physique DECIMAL(10,2) NOT NULL,
    ecart DECIMAL(10,2) GENERATED ALWAYS AS (stock_physique - stock_theorique) STORED,
    valeur_ecart DECIMAL(12,2),
    justification TEXT,
    FOREIGN KEY (inventaire_id) REFERENCES inventaires(id) ON DELETE CASCADE,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Table des alertes de stock
CREATE TABLE alertes_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produit_id INT NOT NULL,
    type_alerte ENUM('stock_bas', 'stock_zero', 'expiration_proche', 'stock_negatif') NOT NULL,
    message TEXT NOT NULL,
    date_alerte TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolue BOOLEAN DEFAULT FALSE,
    date_resolution TIMESTAMP NULL,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Table des pertes et gaspillage
CREATE TABLE pertes_gaspillage (
    id INT PRIMARY KEY AUTO_INCREMENT,
    produit_id INT NOT NULL,
    quantite DECIMAL(10,2) NOT NULL,
    valeur DECIMAL(10,2) NOT NULL,
    motif ENUM('perime', 'abime', 'casse', 'vol', 'erreur', 'autre') NOT NULL,
    description TEXT,
    date_perte DATE NOT NULL,
    responsable VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produit_id) REFERENCES produits(id)
);

-- Insertion des données de base

-- Unités de mesure
INSERT INTO unites_mesure (nom, abreviation) VALUES
('Kilogramme', 'kg'),
('Gramme', 'g'),
('Litre', 'L'),
('Millilitre', 'ml'),
('Pièce', 'pcs'),
('Boîte', 'box'),
('Sac', 'sac'),
('Carton', 'ctn');

-- Catégories de produits
INSERT INTO categories (nom, description) VALUES
('Viandes', 'Steaks, poulet, bacon, etc.'),
('Pains', 'Pains à burger, hot-dog, etc.'),
('Légumes', 'Salade, tomates, oignons, etc.'),
('Fromages', 'Cheddar, emmental, etc.'),
('Sauces', 'Ketchup, mayo, moutarde, etc.'),
('Boissons', 'Sodas, jus, eau, etc.'),
('Accompagnements', 'Frites, onion rings, etc.'),
('Emballages', 'Boîtes, sacs, gobelets, etc.'),
('Condiments', 'Sel, poivre, épices, etc.'),
('Desserts', 'Glaces, cookies, etc.');

-- Fournisseurs exemple
INSERT INTO fournisseurs (nom, contact_nom, telephone, email, adresse, ville, code_postal, conditions_paiement, delai_livraison) VALUES
('Boucherie Centrale', 'Jean Martin', '01.23.45.67.89', 'commandes@boucherie-centrale.fr', '15 Rue de la Viande', 'Paris', '75001', '30 jours', 2),
('Boulangerie Pro', 'Marie Dupont', '01.98.76.54.32', 'pro@boulangerie-pro.fr', '8 Avenue du Pain', 'Boulogne', '92100', '15 jours', 1),
('Légumes Express', 'Pierre Legume', '01.11.22.33.44', 'contact@legumes-express.fr', '22 Marché Central', 'Rungis', '94150', '7 jours', 1),
('Coca-Cola France', 'Service Commercial', '01.55.66.77.88', 'b2b@coca-cola.fr', '1 Esplanade de France', 'Paris', '75042', '30 jours', 3);

-- Produits exemple
INSERT INTO produits (nom, code_produit, categorie_id, fournisseur_id, unite_mesure_id, prix_unitaire, stock_actuel, stock_minimum, stock_maximum, temperature_stockage) VALUES
('Steak haché 150g', 'VIA001', 1, 1, 5, 2.50, 100, 20, 200, 'refrigere'),
('Pain burger classique', 'PAN001', 2, 2, 5, 0.35, 150, 30, 300, 'ambiant'),
('Salade iceberg', 'LEG001', 3, 3, 1, 1.20, 5, 2, 10, 'refrigere'),
('Fromage cheddar tranches', 'FRO001', 4, 1, 5, 0.25, 200, 50, 400, 'refrigere'),
('Ketchup Heinz 10kg', 'SAU001', 5, 4, 5, 15.50, 3, 1, 6, 'ambiant'),
('Coca-Cola 1.5L', 'BOI001', 6, 4, 5, 1.80, 48, 12, 96, 'refrigere');

-- Vues utiles pour le reporting

-- Vue stock faible
CREATE VIEW vue_stock_faible AS
SELECT 
    p.id,
    p.nom,
    p.code_produit,
    c.nom as categorie,
    p.stock_actuel,
    p.stock_minimum,
    um.abreviation as unite,
    f.nom as fournisseur
FROM produits p
JOIN categories c ON p.categorie_id = c.id
JOIN unites_mesure um ON p.unite_mesure_id = um.id
LEFT JOIN fournisseurs f ON p.fournisseur_id = f.id
WHERE p.stock_actuel <= p.stock_minimum AND p.actif = TRUE;

-- Vue valeur du stock
CREATE VIEW vue_valeur_stock AS
SELECT 
    c.nom as categorie,
    COUNT(p.id) as nb_produits,
    SUM(p.stock_actuel * p.prix_unitaire) as valeur_totale
FROM produits p
JOIN categories c ON p.categorie_id = c.id
WHERE p.actif = TRUE
GROUP BY c.id, c.nom;

-- Vue mouvements récents
CREATE VIEW vue_mouvements_recents AS
SELECT 
    ms.id,
    p.nom as produit,
    ms.type_mouvement,
    ms.quantite,
    ms.valeur_totale,
    ms.motif,
    ms.date_mouvement
FROM mouvements_stock ms
JOIN produits p ON ms.produit_id = p.id
ORDER BY ms.date_mouvement DESC
LIMIT 100;

-- Procédures stockées utiles

DELIMITER //

-- Procédure pour ajouter un mouvement de stock
CREATE PROCEDURE AjouterMouvementStock(
    IN p_produit_id INT,
    IN p_type_mouvement ENUM('entree', 'sortie', 'ajustement', 'perte'),
    IN p_quantite DECIMAL(10,2),
    IN p_prix_unitaire DECIMAL(10,2),
    IN p_motif VARCHAR(200),
    IN p_utilisateur VARCHAR(100)
)
BEGIN
    DECLARE v_stock_avant DECIMAL(10,2);
    DECLARE v_stock_apres DECIMAL(10,2);
    DECLARE v_valeur_totale DECIMAL(10,2);
    
    -- Récupérer le stock actuel
    SELECT stock_actuel INTO v_stock_avant FROM produits WHERE id = p_produit_id;
    
    -- Calculer le nouveau stock
    CASE p_type_mouvement
        WHEN 'entree' THEN SET v_stock_apres = v_stock_avant + p_quantite;
        WHEN 'sortie' THEN SET v_stock_apres = v_stock_avant - p_quantite;
        WHEN 'ajustement' THEN SET v_stock_apres = p_quantite;
        WHEN 'perte' THEN SET v_stock_apres = v_stock_avant - p_quantite;
    END CASE;
    
    SET v_valeur_totale = p_quantite * p_prix_unitaire;
    
    -- Insérer le mouvement
    INSERT INTO mouvements_stock (
        produit_id, type_mouvement, quantite, stock_avant, stock_apres,
        prix_unitaire, valeur_totale, motif, utilisateur
    ) VALUES (
        p_produit_id, p_type_mouvement, p_quantite, v_stock_avant, v_stock_apres,
        p_prix_unitaire, v_valeur_totale, p_motif, p_utilisateur
    );
    
    -- Mettre à jour le stock du produit
    UPDATE produits SET stock_actuel = v_stock_apres WHERE id = p_produit_id;
    
END //

-- Procédure pour générer les alertes de stock
CREATE PROCEDURE GenererAlertesStock()
BEGIN
    -- Supprimer les anciennes alertes non résolues
    DELETE FROM alertes_stock WHERE resolue = FALSE;
    
    -- Alertes stock bas
    INSERT INTO alertes_stock (produit_id, type_alerte, message)
    SELECT 
        id,
        'stock_bas',
        CONCAT('Stock bas pour ', nom, ' (', stock_actuel, ' restant, minimum: ', stock_minimum, ')')
    FROM produits 
    WHERE stock_actuel <= stock_minimum AND stock_actuel > 0 AND actif = TRUE;
    
    -- Alertes stock zéro
    INSERT INTO alertes_stock (produit_id, type_alerte, message)
    SELECT 
        id,
        'stock_zero',
        CONCAT('Stock épuisé pour ', nom)
    FROM produits 
    WHERE stock_actuel = 0 AND actif = TRUE;
    
    -- Alertes stock négatif
    INSERT INTO alertes_stock (produit_id, type_alerte, message)
    SELECT 
        id,
        'stock_negatif',
        CONCAT('Stock négatif pour ', nom, ' (', stock_actuel, ')')
    FROM produits 
    WHERE stock_actuel < 0 AND actif = TRUE;
    
    -- Alertes expiration proche (7 jours)
    INSERT INTO alertes_stock (produit_id, type_alerte, message)
    SELECT 
        id,
        'expiration_proche',
        CONCAT('Expiration proche pour ', nom, ' (expire le ', date_expiration, ')')
    FROM produits 
    WHERE date_expiration BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) 
    AND actif = TRUE;
    
END //

DELIMITER ;

-- Événement programmé pour générer automatiquement les alertes (optionnel)
-- SET GLOBAL event_scheduler = ON;
-- CREATE EVENT ev_alertes_stock
-- ON SCHEDULE EVERY 1 HOUR
-- DO CALL GenererAlertesStock();

-- Index pour optimiser les performances
CREATE INDEX idx_produits_stock_minimum ON produits(stock_minimum, stock_actuel);
CREATE INDEX idx_produits_actif ON produits(actif);
CREATE INDEX idx_mouvements_date ON mouvements_stock(date_mouvement);
CREATE INDEX idx_produits_expiration ON produits(date_expiration);
CREATE INDEX idx_alertes_resolue ON alertes_stock(resolue);