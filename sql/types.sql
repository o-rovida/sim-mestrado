CREATE TYPE tipo_obito_enum AS ENUM ('Fetal', 'Nao Fetal');

CREATE TYPE sexo_enum AS ENUM ('Masculino', 'Feminino', 'Ignorado');

CREATE TYPE raca_cor_enum AS ENUM (
    'Branca',
    'Preta',
    'Amarela',
    'Parda',
    'Indigena'
);

CREATE TYPE estado_civil_enum AS ENUM (
    'Solteiro',
    'Casado',
    'Viuvo',
    'Separado judicialmente/Divorciado',
    'Uniao Estavel',
    'Ignorado'
);

CREATE TYPE escolaridade_nivel_2010_enum AS ENUM (
    'Sem Escolaridade',
    'Fundamental I',
    'Fundamental II',
    'Medio',
    'Superior Incompleto',
    'Superior Completo',
    'Ignorado'
);

CREATE TYPE local_ocorrencia_enum AS ENUM (
    'Hospital',
    'Outros Estabelecimentos de Saude',
    'Domicilio',
    'Via Publica',
    'Outros',
    'Aldeia Indigena',
    'Ignorado'
);

CREATE TYPE gravidez_tipo_enum AS ENUM ('Unica', 'Dupla', 'Tripla e mais', 'Ignorada');

CREATE TYPE parto_tipo_enum AS ENUM ('Vaginal', 'Cesareo', 'Ignorado');

CREATE TYPE morte_parto_relacao_enum AS ENUM ('Antes', 'Durante', 'Depois', 'Ignorado');

CREATE TYPE tipo_morte_ocorrencia_enum AS ENUM (
    'Na gravidez',
    'No parto',
    'No abortamento',
    'Ate 42 dias apos o termino do parto',
    'De 43 dias a 1 ano apos o termino da gestacao',
    'Nao ocorreu nestes periodos',
    'Ignorado'
);

CREATE TYPE sim_nao_ignorado_enum AS ENUM ('Sim', 'Nao', 'Ignorado');

CREATE TYPE atestante_condicao_enum AS ENUM (
    'Assistente',
    'Substituto',
    'IML',
    'SVO',
    'Outro'
);

CREATE TYPE circunstancia_obito_enum AS ENUM (
    'Acidente',
    'Suicidio',
    'Homicidio',
    'Outros',
    'Ignorado'
);

CREATE TYPE fonte_informacao_enum AS ENUM (
    'Ocorrencia policial',
    'Hospital',
    'Familia',
    'Outra',
    'Ignorado'
);

CREATE TYPE tipo_obito_ocorrencia_acidente_enum AS ENUM (
    'Via Publica',
    'Residencia',
    'Outro Domicilio',
    'Estabelecimento Comercial',
    'Outros',
    'Ignorada'
);

CREATE TYPE origem_dados_enum AS ENUM (
    'Oracle',
    'Banco Estadual FTP',
    'Banco SEADE',
    'Ignorado'
);

CREATE TYPE escolaridade_anos_enum AS ENUM (
    'Nenhuma',
    '1 a 3 anos',
    '4 a 7 anos',
    '8 a 11 anos',
    '12 anos e mais',
    'Ignorado'
);

CREATE TYPE obito_puerperio_enum AS ENUM (
    'Sim, ate 42 dias apos o parto',
    'Sim, de 43 dias a 1 ano',
    'Nao',
    'Ignorado'
);

CREATE TYPE fonte_investigacao_enum AS ENUM (
    'Comite de Morte Materna e/ou Infantil',
    'Visita domiciliar / Entrevista familia',
    'Estabelecimento de Saude / Prontuario',
    'Relacionado com outros bancos de dados',
    'SVO',
    'IML',
    'Outra fonte',
    'Multiplas fontes',
    'Ignorado'
);

CREATE TYPE escolaridade_agregada_enum AS ENUM (
    'Sem Escolaridade',
    'Fundamental I Incompleto',
    'Fundamental I Completo',
    'Fundamental II Incompleto',
    'Fundamental II Completo',
    'Ensino Medio Incompleto',
    'Ensino Medio Completo',
    'Superior Incompleto',
    'Superior Completo',
    'Ignorado',
    'Fundamental I Incompleto ou Inespecifico',
    'Fundamental II Incompleto ou Inespecifico',
    'Ensino Medio Incompleto ou Inespecifico'
);

CREATE TYPE nivel_investigador_enum AS ENUM ('Estadual', 'Regional', 'Municipal');