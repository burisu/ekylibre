DROP TABLE IF EXISTS technical_workflow_procedure_items;
DROP TABLE IF EXISTS technical_workflow_procedures;
DROP TABLE IF EXISTS technical_workflows;

        CREATE TABLE technical_workflows (
          id character varying PRIMARY KEY NOT NULL,
          family character varying,
          production_reference_name character varying,
          production_system character varying,
          start_day integer,
          start_month integer,
          unit character varying,
          life_state character varying,
          life_cycle character varying,
          plant_density integer,
          translation_id character varying NOT NULL
        );

        CREATE INDEX technical_workflows_id ON technical_workflows(id);
        CREATE INDEX technical_workflows_family ON technical_workflows(family);
        CREATE INDEX technical_workflows_production_reference_name ON technical_workflows(production_reference_name);

        CREATE TABLE technical_workflow_procedures (
          id character varying PRIMARY KEY NOT NULL,
          position integer NOT NULL,
          name jsonb NOT NULL,
          repetition integer,
          frequency character varying,
          period character varying,
          bbch_stage character varying,
          procedure_reference character varying NOT NULL,
          technical_workflow_id character varying NOT NULL
        );

        CREATE INDEX technical_workflows_procedures_technical_workflow_id ON technical_workflow_procedures(technical_workflow_id);
        CREATE INDEX technical_workflows_procedures_procedure_reference ON technical_workflow_procedures(procedure_reference);

        CREATE TABLE technical_workflow_procedure_items (
          id character varying PRIMARY KEY NOT NULL,
          actor_reference character varying,
          procedure_item_reference character varying,
          article_reference character varying,
          quantity numeric(19,4),
          unit character varying,
          procedure_reference character varying NOT NULL,
          technical_workflow_procedure_id character varying NOT NULL
        );

        CREATE INDEX technical_workflow_procedure_items_technical_workflow_pro_id ON technical_workflow_procedure_items(technical_workflow_procedure_id);
        CREATE INDEX technical_workflow_procedure_items_procedure_reference ON technical_workflow_procedure_items(procedure_reference);
