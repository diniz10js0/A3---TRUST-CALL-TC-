-- banco de dados do fraudshield
-- criado para o hackathon bradesco 2024
-- compativel com MySQL

CREATE DATABASE IF NOT EXISTS fraudshield;
USE fraudshield;

-- tabela de usuarios
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- tabela de denuncias
-- risk_level pode ser: BAIXO, MEDIO, ALTO, CRITICO
-- scam_type pode ser: FALSO_BANCO, FALSO_SUPORTE, PIX_FALSO, WHATSAPP_CLONADO, PHISHING, VISHING, OUTRO
CREATE TABLE IF NOT EXISTS reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    description VARCHAR(1000) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    scam_type VARCHAR(30),
    created_at TIMESTAMP DEFAULT NOW(),
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- tabela de dicas de seguranca
CREATE TABLE IF NOT EXISTS tips (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content VARCHAR(2000) NOT NULL,
    category VARCHAR(100) NOT NULL,
    icon_url VARCHAR(500)
);

-- inserindo algumas dicas iniciais
INSERT INTO tips (title, content, category, icon_url) VALUES
('Nunca forneça sua senha por telefone', 'Bancos NUNCA ligam pedindo senha, token ou código. Se receber essa ligação, desligue imediatamente.', 'LIGACAO', '🔒'),
('Desconfie de urgência e pressão', 'Golpistas criam senso de urgência para impedir que você pense. Frases como sua conta será bloqueada agora são sinais de golpe.', 'PSICOLOGIA', '⚠️'),
('Verifique o número antes de atender', 'Números de bancos geralmente começam com 0800. Números de celular pedindo dados são suspeitos.', 'LIGACAO', '📞'),
('Cuidado com PIX urgente', 'Se alguém pede PIX urgente mesmo sendo familiar em apuro, confirme a identidade antes de transferir.', 'PIX', '💸'),
('Links suspeitos no WhatsApp', 'Não clique em links de números desconhecidos. Promoções impossíveis são iscas para roubo de dados.', 'WHATSAPP', '📱'),
('Ative o duplo fator de autenticação', 'Sempre ative o 2FA no app do banco e redes sociais. Dificulta muito o acesso de golpistas.', 'SEGURANCA_DIGITAL', '🛡️');

-- view que resume o risco de cada numero de telefone
-- usa CASE pra calcular o pior risco com peso real, nao alfabetico
-- sem isso MEDIO seria "maior" que CRITICO na ordenacao de texto
CREATE OR REPLACE VIEW vw_phone_risk_summary AS
SELECT
    phone_number,
    COUNT(*) AS total_reports,

    -- pega o nome do nivel de risco mais grave encontrado
    CASE MAX(
        CASE risk_level
            WHEN 'BAIXO'   THEN 1
            WHEN 'MEDIO'   THEN 2
            WHEN 'ALTO'    THEN 3
            WHEN 'CRITICO' THEN 4
        END
    )
        WHEN 1 THEN 'BAIXO'
        WHEN 2 THEN 'MEDIO'
        WHEN 3 THEN 'ALTO'
        WHEN 4 THEN 'CRITICO'
    END AS highest_risk,

    MIN(created_at) AS first_report,
    MAX(created_at) AS last_report

FROM reports
GROUP BY phone_number;
