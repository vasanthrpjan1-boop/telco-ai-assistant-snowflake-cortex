# 3 - Analyse your data with Cortex Analyst
In this section you will learn how to build a dynamic data explorer using Cortex Analyst


### Examine the Structured Marketplace Data

First of all, navigate to the Cortex Analyst notebook with the projects data to perform the following:

-   Create a new dataset from the market place
-   Visualise the data in Streamlit

Once you have completed the notebook, return here

<hr>

### Use Cortex Analyst to Explore the data
It is easy to create an app in order to gain insights from structured data.  **Cortex Analyst** allows the user to ask questions in natural language and will return the result in an appropiate format.  Let's Begin:

- Go back to the home page and click on **AI & ML**

- Press **Try** on **Cortex Analyst**

![create build](assets/analyst/C001.png)


Choose **DATAOPS_EVENT_PROD.CORTEX_ANALYST** as the schema and **CORTEX_ANALYST** as the stage

<hr>

- Press **Create New** to create a new Semantic model about the previously loaded dataset

Below you will see the **Semantic Model** wizard.  This will create a YAML file which makes sense of the data ane provides a link between the sorts of questions that might be asked and the dataset itself.  

- Populate the fields as the screenshot below:

![alt text](image.png)

- Press **Next**


The next step you will need to provide sample questions of what might be asked about the dataset.  Tryout the following:

```text
What is the latest stock price for SNOW share?

Tell me the stock prices for SNOW Shares last week by day of the week?

What is the stock prices for SNOW shares by month?

```

Press **Next**

- Under the **DATAOPS_EVENT_PROD.DEFAULT_SCHEMA** view, select the **STOCK_PRICES** view.
- Press **Next**
- Select all relevent columns and then press **Done**

Next, you will need to specify what fields are Dimensions, Time Dimensions, Facts, Named Fields or Metrics.  As you try this out, you will see example outputs

![alt text](assets/analyst/C003.png)

- Press *Save* to save the YAML file which will be used in Streamlit

- Let's now move to **Step 4** to start collecting unstructured data about the share prices.