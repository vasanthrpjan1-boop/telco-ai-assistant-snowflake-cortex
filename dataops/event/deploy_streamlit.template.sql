use role ACCOUNTADMIN;

create schema if not exists {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }};
-----create notebook and streamlit stages
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
CREATE STAGE IF NOT EXISTS {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3 DIRECTORY = (ENABLE = TRUE) ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');


------put streamlit files in stages
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_analyst/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_analyst/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_analyst/config.toml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1/.streamlit auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/Snowflake_dots.png @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1/ auto_compress = false overwrite = true;
-------put streamlit 2 in stage
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/config.toml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2/.streamlit auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/Snowflake_dots.png @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2/ auto_compress = false overwrite = true;
-------put streamlit 3 in stage
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_search/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_search/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3 auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_search/config.toml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3/.streamlit auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/logos/snowflake_logo_color_rgb.svg @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/homepage/docs/stylesheets/extra.css @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3/ auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR }}/dataops/event/streamlit/cortex_chat/Snowflake_dots.png @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3/ auto_compress = false overwrite = true;
-----CREATE STREAMLITS

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.cortex_analyst
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT1'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '{"origin":"sf_sit", "name":"cortex_analyst", "version":{"major":1, "minor":0}, "attributes":{"is_quickstart":0, "source":"streamlit"}}';

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_AGENT
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT2'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '{"origin":"sf_sit", "name":"CORTEX_CHAT", "version":{"major":1, "minor":0}, "attributes":{"is_quickstart":0, "source":"streamlit"}}';

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.CORTEX_SEARCH
ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.STREAMLIT3'
MAIN_FILE = 'app.py'
QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}'
COMMENT = '{"origin":"sf_sit", "name":"CORTEX_SEARCH", "version":{"major":1, "minor":0}, "attributes":{"is_quickstart":0, "source":"streamlit"}}';


