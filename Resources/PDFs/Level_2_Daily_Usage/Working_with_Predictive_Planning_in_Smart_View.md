# Working with Predictive Planning in Smart View — Complete Markdown Edition

> **Original PDF:** `Working_with_Predictive_Planning_in_Smart_View.pdf` | **Folder:** Level 2 (Daily Usage)  
> **Purpose:** Definitive Markdown guide on executing statistical time-series prediction models (`Predictive Planning`) directly inside Excel Smart View grids.

---

## Table of Contents
1. [Launching Predictive Planning in Excel](#launching-predictive)
2. [Statistical Best-Fit Models (`ARIMA`, `ETS`) & Charting](#models-and-charting)
3. [Pasting Predictions into Excel Forms & Saving](#pasting-predictions)
4. [Cross-Reference in Course Modules](#cross-reference)

---

## 1. Launching Predictive Planning in Excel <a name="launching-predictive"></a>

1. Open a Smart View web form containing historical actuals (`FY23 - FY25`) and future forecast periods (`FY26`).
2. Click `Predictive Planning -> Predict` on the Excel ribbon.
3. The engine scans all historical rows and opens the interactive **Predictive Planning Panel** inside Excel.

---

## 2. Statistical Best-Fit Models (`ARIMA`, `ETS`) & Charting <a name="models-and-charting"></a>

- **Visual Prediction Bands:** Displays historical actual line overlaid with future predicted trend curves and shaded **95% Confidence Interval bands** (`Best Case vs. Worst Case`).
- **Algorithm Tournament:** Evaluates `ARIMA`, `Damped Trend`, and `Holt-Winters Seasonal` on the fly, auto-selecting the model with the lowest statistical error (`RMSE`).

---

## 3. Pasting Predictions into Excel Forms & Saving <a name="pasting-predictions"></a>

Planners click **Paste** inside the Predictive panel to write the AI's predicted numbers directly into the form's editable `Working` cells (`FY26 Jan - Dec`). They can then tweak numbers slightly and hit **Save (`Ctrl + Alt + S`)** to commit to Essbase.

---

## 4. Cross-Reference in Course Modules <a name="cross-reference"></a>

- **`24_Architect_Masterclass/07_IPM_Insights_and_Auto_Predict_AI_Engine.md`** — Deep architectural mechanics of auto-predict algorithms.
