use role {{ env.EVENT_ATTENDEE_ROLE }};

create schema if not exists {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }};
create stage if not exists {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.EXAMPLE_STREAMLIT_STAGE;

PUT file:///{{ env.CI_PROJECT_DIR}}/solution/streamlit/app.py @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.EXAMPLE_STREAMLIT_STAGE auto_compress = false overwrite = true;
PUT file:///{{ env.CI_PROJECT_DIR}}/solution/streamlit/environment.yml @{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.EXAMPLE_STREAMLIT_STAGE auto_compress = false overwrite = true;

CREATE OR REPLACE STREAMLIT {{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.EXAMPLE_STREAMLIT
    ROOT_LOCATION = '@{{ env.DATAOPS_DATABASE }}.{{ env.STREAMLIT_SCHEMA }}.EXAMPLE_STREAMLIT_STAGE'
    MAIN_FILE = 'app.py'
    QUERY_WAREHOUSE = '{{ env.EVENT_WAREHOUSE }}';
