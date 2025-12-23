https://gemini.google.com/app/e545eef66f420855

Here is a comprehensive blueprint/specification for the ImageNet Hierarchy Explorer. You can copy-paste this entire block into an LLM prompt to generate the application.

---

# Application Specification: ImageNet Hierarchy Explorer

## 1. Overview

Build a single-file web application (HTML/CSS/JS) to visualize, explore, and search the ImageNet/WordNet hierarchy. The application parses a specific JSON schema representing a Directed Acyclic Graph (DAG) of synsets and renders it as an interactive collapsible tree.

## 2. Technical Stack

* **Format:** Single HTML file (embedded CSS/JS).
* **Frameworks:**
* **Bootstrap 5.3+**: For UI layout (toolbar, sidebar, grid).
* **D3.js v7.8.5+**: For tree visualization and interaction.
* **Constraint:** No external build steps (e.g., Webpack/React). Pure browser-native JavaScript.

## 3. Data Schema & Parsing

The app must ingest a JSON file with the following structure:

* **Arrays:** `rid` (unique ID), `sid` (string name), `ilsvrc_class_id` (ImageNet class ID), `path_rid` (array of arrays of RIDs).
* **Parsing Logic:**
    1. **Metadata Map:** Create a lookup map: `RID -> { sid, class_id }`.
    2. **Tree Construction:**
        * The input is a list of paths (arrays of RIDs).
        * Merge these paths into a single hierarchical tree structure suitable for `d3.hierarchy`.
* **Virtual Root:** If multiple top-level nodes exist, create a virtual "World" root node.
* **Duplicate Nodes:** Since it is a DAG displayed as a Tree, the same RID may appear in multiple branches. Treat them as distinct visual nodes but link them to the same metadata.

## 4. UI Layout

### A. Global Layout

* **Viewport:** `100vh` height, `overflow: hidden`.
* **Top Bar:** Toolbar containing:
* File Input (Upload JSON).
* Status Text (Filename or "Processing...").
* Search Input (Disabled until data load).
* "Expand All" / "Collapse All" buttons.


* **Main Body:** Flex container.
* **Left (Canvas):** Takes remaining width. Hosts the SVG.
* **Right (Sidebar):** Fixed width (~300px), bordered.

### B. Sidebar Content

1. **Top (Details Pane):** Shows details of the currently hovered/selected node:
* Node Name (`sid`).
* RID.
* Type (Class vs Internal).
* Statistics (Subtree counts).


2. **Bottom (Search Results):**
* Hidden by default.
* Appears when search has results.
* Scrollable list of matches.
* Shows count of matches.

## 5. Feature Specifications

### A. Visualization (D3.js)

* **Type:** Tidy Tree (`d3.tree`).
* **Orientation:** Horizontal (Root on Left, leaves on Right).
* **Node Styling:**
* **ImageNet Class (ilsvrc_class_id >= 0):** Blue circle (`#0d6efd`), larger radius.
* **Internal Node:** Grey circle (`#ccc`), smaller radius.
* **Selected Node:** Red circle, highlighted stroke.


* **Labels:**
* Display `sid` (Synset ID).
* **Statistics Display:** Next to the name, display `[Blue Count] / [Grey Count]`.
* **Blue Count:** Number of valid ImageNet classes in the subtree.
* **Grey Count:** Total number of nodes in the subtree.
* **Critical Logic:** Use a `Set` data structure during calculation to ensure unique RIDs are **not double-counted** (since the graph is a DAG).

* **Interactions:**
* **Click:** Expand/Collapse children.
* **Hover:** Update Sidebar Details pane.
* **Zoom/Pan:** Enabled on the SVG canvas.



### B. Search Functionality

* **Matching Logic:**
* Case-insensitive.
* **Underscore/Space Agnostic:** Input "kit fox" must match "kit_fox".


* **Ranking:** Sort results by:
1. Exact Match.
2. Starts With.
3. Alphabetical.


* **Action:** Clicking a result must:
1. Find the corresponding node in the D3 hierarchy (handle duplicates if multiple visual nodes share the RID; pick the first found).
2. Programmatically expand all parents of that node.
3. Set the node as "Selected" (Red).
4. **Zoom & Center:** Apply a D3 zoom transform to center the node on screen.
* *Formula:* `translate(width/2 - y*scale, height/2 - x*scale)`.





### C. State Management

* **Loading State:** Show a full-screen spinner overlay while parsing large JSON files.
* **Resize Handler:** Re-render or update D3 dimensions on window resize.
* **Error Handling:**
* Catch JSON parse errors.
* Prevent `null` pointer errors during resize if data isn't loaded.



## 6. Detailed Algorithms

### Tree Stats Calculation (DFS)

```javascript
function calculateStats(node) {
    const allRids = new Set([node.rid]);
    const validRids = new Set(node.class_id >= 0 ? [node.rid] : []);

    if (node.children) {
        node.children.forEach(child => {
            const childStats = calculateStats(child);
            childStats.allRids.forEach(r => allRids.add(r));
            childStats.validRids.forEach(r => validRids.add(r));
        });
    }
    // Store sizes for display
    node.statValid = validRids.size;
    node.statTotal = allRids.size;
    return { allRids, validRids };
}

```

### Search Matching

```javascript
const queryClean = input.trim().replace(/\s+/g, '_');
// Match if SID includes raw input OR queryClean

```

---

### Prompt to generate this app:

> "Generate a single-file HTML application based on the 'ImageNet Hierarchy Explorer' specification above. Ensure all CSS is embedded, D3.js is loaded via CDN, and the specific algorithms for DAG statistical counting and Zoom-to-Node centering are implemented exactly as described."
