You will be given a URL to an Observable notebook and a path to a markdown file. Your task is to update the frontmatter of the markdown file with information from the notebook.

Here are the steps to follow:

1.  You are in the `/storage/BA69-0000/Vaults/dhammacharts/vault/content/_charts` directory. Read the `prompt.md` file in this directory to understand the desired frontmatter structure.

2.  The notebook URL will be in the format `https://observablehq.com/@user/notebook-name`. To get the raw content of the notebook, you need to fetch the JavaScript module by using the URL `https://api.observablehq.com/@user/notebook-name.js`. you can use as well https://api.observablehq.com/d/chart-id.js

3.  From the content of the JavaScript module, extract the following information:
    *   `title`: The title of the notebook.
    *   `author`: The author of the notebook.
    *   `year`: The year of publication. If not available, use the current year.
    *   `license`: The license of the notebook. Look for a specific license like "CC BY-NC 4.0".
    *   `sources`: A list of sources used in the notebook. Include the name and author if available.
    *   `techs`: The technologies used in the notebook (e.g., D3, Observable).

4.  Read the markdown file specified in the prompt.

5.  Update the frontmatter of the markdown file with the information you extracted from the notebook. Make sure the frontmatter follows the structure from `prompt.md`.

6.  Generate a concise one-paragraph description of the chart based on the notebook's content and add it below the frontmatter.

7.  Inform me when you are done.

Example usage:

"Please update the file `digital/my-chart.md` using the notebook at `https://observablehq.com/@user/my-chart`."

**Workflow Hint:**

When fetching content from a URL, it's better to download the file locally and then read it, instead of using web_fetch and parsing the output.