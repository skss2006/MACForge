import csv
import json

def generate_html():
    tests_data = {} 
    
    try:
        with open('sim_data.csv', 'r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                test_name = row.get('TestName', 'Unknown Test')
                if test_name not in tests_data:
                    tests_data[test_name] = []
                    
                grid = []
                for r in range(4):
                    grid_row = []
                    for c in range(4):
                        grid_row.append(int(row.get(f'C{r}{c}', 0)))
                    grid.append(grid_row)
                    
                tests_data[test_name].append({
                    "cycle": int(row.get('Cycle', 0)), 
                    "grid": grid
                })
    except FileNotFoundError:
        print("Error: sim_data.csv not found!")
        return

    json_data = json.dumps(tests_data)

    html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>WS Systolic Array Verification</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, sans-serif; background: #1e1e1e; color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }}
        .dashboard {{ background: #2d2d2d; padding: 40px; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); text-align: center; max-width: 800px; width: 100%; }}
        select {{ font-size: 18px; padding: 8px; margin-bottom: 20px; border-radius: 6px; background: #3d3d3d; color: white; border: 1px solid #555; }}
        .cycle-text {{ color: #4caf50; font-weight: bold; font-size: 18px; margin-bottom: 20px; }}
        .grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 30px; }}
        .node {{ background: #3d3d3d; border: 2px solid #555; border-radius: 6px; width: 100%; height: 70px; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: bold; overflow: hidden; }}
        .controls button {{ background: #007bff; color: white; border: none; padding: 10px 20px; font-size: 16px; border-radius: 6px; cursor: pointer; margin: 0 10px; }}
        .controls button:disabled {{ background: #555; cursor: not-allowed; color: #888; }}
    </style>
</head>
<body>
    <div class="dashboard">
        <h2>4x4 Systolic Array (32-bit Signed)</h2>
        
        <select id="test-selector" onchange="changeTest()"></select>

        <div class="cycle-text" id="cycle-display">Cycle 1</div>
        <div class="grid" id="grid-container"></div>
        <div class="controls">
            <button id="btn-prev" onclick="changeCycle(-1)">&#8592; Previous</button>
            <button id="btn-next" onclick="changeCycle(1)">Next &#8594;</button>
        </div>
    </div>
    
    <script>
        const testsData = {json_data};
        let currentTestName = "";
        let currentIndex = 0;

        function init() {{
            const selector = document.getElementById('test-selector');
            const testKeys = Object.keys(testsData);
            
            // ERROR HANDLING: If the CSV was empty, show a warning!
            if (testKeys.length === 0) {{
                document.getElementById('cycle-display').innerText = "ERROR: No Data Found!";
                document.getElementById('cycle-display').style.color = "#ff5555";
                document.getElementById('grid-container').innerHTML = "<div style='grid-column: span 4; font-size: 18px;'>Your sim_data.csv is empty! Make sure your Verilog simulation runs all the way to $finish.</div>";
                document.getElementById('btn-prev').disabled = true;
                document.getElementById('btn-next').disabled = true;
                selector.disabled = true;
                return;
            }}

            currentTestName = testKeys[0];
            
            for (let testName of testKeys) {{
                let option = document.createElement('option');
                option.value = testName;
                option.innerText = testName;
                selector.appendChild(option);
            }}
            updateUI();
        }}

        function changeTest() {{
            currentTestName = document.getElementById('test-selector').value;
            currentIndex = 0; // Reset to cycle 1 for the new test
            updateUI();
        }}

        function updateUI() {{
            const currentSimData = testsData[currentTestName];
            document.getElementById('cycle-display').innerText = 'Clock Cycle ' + currentSimData[currentIndex].cycle;
            
            let gridHTML = '';
            for(let r=0; r<4; r++) {{
                for(let c=0; c<4; c++) {{
                    gridHTML += `<div class="node">${{currentSimData[currentIndex].grid[r][c]}}</div>`;
                }}
            }}
            document.getElementById('grid-container').innerHTML = gridHTML;

            document.getElementById('btn-prev').disabled = (currentIndex === 0);
            document.getElementById('btn-next').disabled = (currentIndex === currentSimData.length - 1);
        }}

        function changeCycle(step) {{
            currentIndex += step;
            updateUI();
        }}
        
        init();
    </script>
</body>
</html>"""

    with open('index.html', 'w', encoding='utf-8') as file:
        file.write(html_template)
    print("Success! Open 'index.html' in your web browser.")

if __name__ == "__main__":
    generate_html()