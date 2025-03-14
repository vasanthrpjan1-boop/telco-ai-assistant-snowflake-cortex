use role ACCOUNTADMIN;

create or replace schema {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }};
--CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK3 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK4 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK5 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK6 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

------put notebook files in stages
--PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/buy_or_sell.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 auto_compress = false overwrite = true;
--PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 auto_compress = false overwrite = true;

PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/cortex_analyst.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK4 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK4 auto_compress = false overwrite = true;

PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/DOCUMENT_AI_ANALYST_REPORTS.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK5 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK5 auto_compress = false overwrite = true;

PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/SEARCH_SERVICE.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK6 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK6 auto_compress = false overwrite = true;


PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/sound_analysis/sound_service_with_transcripts.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/sound_analysis/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/infographics/DOCUMENT_AI_infographics.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK3 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/infographics/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK3 auto_compress = false overwrite = true;

--create notebooks
CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.CORTEX_ANALYST
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK4'
MAIN_FILE = 'cortex_analyst.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.CORTEX_ANALYST ADD LIVE VERSION FROM LAST;


CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.ANALYSE_SOUND
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2'
MAIN_FILE = 'sound_service_with_transcripts.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.ANALYSE_SOUND ADD LIVE VERSION FROM LAST;


CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.DOCUMENT_AI_INFOGRAPHICS
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK3'
MAIN_FILE = 'DOCUMENT_AI_infographics.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.DOCUMENT_AI_INFOGRAPHICS ADD LIVE VERSION FROM LAST;

CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.DOCUMENT_AI_ANALYST_REPORTS
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK5'
MAIN_FILE = 'DOCUMENT_AI_ANALYST_REPORTS.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.DOCUMENT_AI_ANALYST_REPORTS ADD LIVE VERSION FROM LAST;

CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.SEARCH_SERVICE
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK6'
MAIN_FILE = 'SEARCH_SERVICE.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.SEARCH_SERVICE ADD LIVE VERSION FROM LAST;