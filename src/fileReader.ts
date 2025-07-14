import spacetime from "spacetime";
import { JSDOM } from "jsdom";
import fs from "fs";

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

// validate and process retreived data
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
if (htmlText === "") {
  console.log("No content to write to file.");
  process.exit(0);
}
// format content for file output   

const dom = new JSDOM(htmlText);
const doc = dom.window.document;
const header = `${websiteUrl} - ${doc.querySelectorAll("h1.text-xl")[0].textContent}`;
const passages = doc.querySelectorAll("div.mt-32")[0].querySelectorAll('span:not([class])');
const unpaddedDate = () => {
  let month = s.month() + 1;
  let date = s.date();
  let year = s.year();

  return `${month}/${date}/${year}`;
}
let bodyText = `date: ${unpaddedDate()}\nbody:\n${header}\n`; //0-based month numbers
passages.forEach((passage: Element) => {
  bodyText += `-\n\n\n${passage.textContent}\n\n${DIVIDER}\n`;
})
bodyText += "-";

// Write the content to a file
try  {
  fs.writeFileSync("output.txt",bodyText, "utf8" );
  console.log("File written successfully");
}
catch (error) {
  console.error("Error writing file: " + error);
}