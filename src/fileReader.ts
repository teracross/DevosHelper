import spacetime from "spacetime";
import { JSDOM } from "jsdom";

const DIVIDER = "---- Devos ----";
let s = spacetime.today();
s.nearest("day");
const dayOfYearTitle = s.dayOfYear();
console.debug("current day of the year: " + dayOfYearTitle);

const websiteUrl = `https://bible.alpha.org/en/classic/${dayOfYearTitle}/index.html`;
console.debug("The website for the page is: " + websiteUrl);

// Function to fetch data from the website
// This function fetches the content of the Bible in One Year website for the current day
// and returns it as a string. If an error occurs, it logs the error and returns null.
async function fetchData(website: string): Promise<string | null> {
  try {
    const response = await fetch(website);
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    return response.text();
  } catch (error: unknown) {
    if (error instanceof Error) console.error(error.message);
    else console.error("Unknown error: " + String(error));
    return null; // Return null in case of error
  }
}

const htmlText = await fetchData(websiteUrl)
  .then((data) => {
    let text: string = "";
    if (data === null || (typeof data === "string" && data.trim().length === 0)) 
    {
      console.log("No data received from Bible in One Year website ");
    } 
    else if (typeof data === "string" && data.trim() !== "") 
    {
      text = data;
    }
    else {
      console.log("Unable to retreive Bible in One Year website contents");
    }

    return text;
  })
  .catch((error) => {
    console.error("Error fetching data: " + error);
    console.log("Bible in One Year website contents: Error fetching data");
    return "";
  })

const dom = new JSDOM(htmlText);
const doc = dom.window.document;
const header = `${websiteUrl} - ${doc.querySelectorAll("h1.text-xl")[0].textContent}`;
console.log("Header: " + header)
const passages = doc.querySelectorAll("div.mt-32")[0].querySelectorAll('span:not([class])');
let bodyText = "";
passages.forEach((passage: Element) => {
  bodyText += `-\n\n\n${passage.textContent}\n\n${DIVIDER}\n`;
})
bodyText += "-";
console.log("Body Text:\n" + bodyText);