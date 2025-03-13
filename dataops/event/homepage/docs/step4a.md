# 3b - Cortex Analyst - Add Additional Structured Datasets

We have now generated more Structured Data from the infographics.  You will now add this additional information to the symantic Model for **Cortex Analyst**

- Within the **Snowflake AI and ML Studio**, click on **Cortex Analyst**
- Choose **DATAOPS_EVENT_PROD.CORTEX_ANALYST** for the Database and Schema
- Choos **Cortex Analyst** for the STAGE.
- Select the previously built yaml file.

- Press **Open**


Now we are in the edit screen.  You will see the existing setup - but now, we will add an additional table.

- Click on the **+** nedt to **Logical tables**.

- Under DATAOPS_EVENT_PROD.DOCUMENT_AI, select **EARNINGS_INFOGRAPHIC_PARSED**.

![create build](assets/analyst/C005.png)

- Press **Next**

- Select all fields.

- Press **Done**

You can now browse through the Dimensions, Time dimensions and Facts to see if everything is as expected.  You have the opportunity to make amendmendmend and add **Synonyms** to each field

You can now test cortex analyst out from here.  For instance,

- In the prompt ask ** What is the product Revenue in 2023**

Cortex will Present you with an answer as well as a sample query.  If you think this is correct, you can add it as a **Verified Query**.

![create build](assets/analyst/C006.png)

When you have finished editing the **Semantic Model** press **Save** which is at the top right hand corner of the screen.
