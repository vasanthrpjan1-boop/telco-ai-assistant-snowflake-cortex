use role {{ env.EVENT_ATTENDEE_ROLE }};

create schema if not exists {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }};
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

------put notebook files in stages
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/buy_or_sell.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/buy_or_sell/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/sound_analysis/sound_service_with_transcripts.ipynb @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/notebooks/sound_analysis/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2 auto_compress = false overwrite = true;

--create notebooks
CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.BUY_OR_SELL
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK1'
MAIN_FILE = 'buy_or_sell.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.BUY_OR_SELL ADD LIVE VERSION FROM LAST;


CREATE OR REPLACE NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.ANALYSE_SOUND
FROM '@{{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.NOTEBOOK2'
MAIN_FILE = 'sound_service_with_transcripts.ipynb'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';

ALTER NOTEBOOK {{ env.DATAOPS_DATABASE }}.{{ env.NOTEBOOKS_SCHEMA }}.ANALYSE_SOUND ADD LIVE VERSION FROM LAST;