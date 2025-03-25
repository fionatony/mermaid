const express = require("express");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const cors = require("cors");
const util = require("util");
const execPromise = util.promisify(exec);

const app = express();
const port = 7777;

// Enable CORS for all routes
app.use(cors());

// Create temp directory if it doesn't exist
const tempDir = path.join(__dirname, "temp");
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir);
}

app.get("/render", async (req, res) => {
  const { code, format, width, height } = req.query;

  if (!code) {
    return res
      .status(400)
      .json({ error: "Missing mermaid code in query parameter" });
  }

  try {
    // Create unique filename for this request
    const timestamp = Date.now();
    const outputFormat = format === "svg" ? "svg" : "png";
    const inputFile = path.join(tempDir, `diagram-${timestamp}.mmd`);
    const outputFile = path.join(
      tempDir,
      `diagram-${timestamp}.${outputFormat}`
    );

    // Write mermaid code to temporary file
    fs.writeFileSync(inputFile, decodeURIComponent(code));

    // Set up the mmdc command with proper configuration
    let mmdcCmd = `mmdc-wrapper -i "${inputFile}" -o "${outputFile}" -b transparent -c mmdc-config.json`;

    // Add width and height parameters if provided
    if (width) {
      mmdcCmd += ` -w ${width}`;
    }
    if (height) {
      mmdcCmd += ` -H ${height}`;
    }

    console.log("Executing command:", mmdcCmd);

    // Execute mmdc command
    const { stdout, stderr } = await execPromise(mmdcCmd);

    if (stderr) {
      console.error("MMDC stderr:", stderr);
    }

    if (stdout) {
      console.log("MMDC stdout:", stdout);
    }

    // Check if the output file exists
    if (!fs.existsSync(outputFile)) {
      throw new Error("Output file was not generated");
    }

    // Set the proper content type based on format
    if (outputFormat === "svg") {
      res.contentType("image/svg+xml");
    } else {
      res.contentType("image/png");
    }

    // Send the generated file
    res.sendFile(outputFile, (err) => {
      if (err) {
        console.error(`Error sending file: ${err}`);
      }
      // Clean up temporary files
      try {
        fs.unlinkSync(inputFile);
        fs.unlinkSync(outputFile);
      } catch (cleanupError) {
        console.error("Error cleaning up files:", cleanupError);
      }
    });
  } catch (error) {
    console.error(`Server error: ${error.message}`);
    console.error(error.stack);
    res
      .status(500)
      .json({ error: "Failed to generate diagram", details: error.message });
  }
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
});
