# Deploying Meal Plan

This guide includes **GitHub Pages as a deployment option** and explains when you need a separate Python host.

- Repository: https://github.com/Mealplan193/MealPlan
- Current public website: https://mealplan193.github.io/MealPlan/

## Option A — GitHub Pages (static website)

Choose this option if you want to publish the browser-based HTML/CSS/JavaScript version using GitHub.

1. Open the repository: https://github.com/Mealplan193/MealPlan
2. Upload or push the website files to the repository. Make sure `index.html` is in the folder you plan to publish.
3. Open **Settings → Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Select the branch containing `index.html` (usually `main`) and the folder (`/(root)` if `index.html` is in the repository root).
6. Click **Save** and wait for GitHub Pages to finish deploying.
7. Open https://mealplan193.github.io/MealPlan/ to test the published site.
8. To update it later, commit and push your changes to the selected branch and folder. GitHub Pages republishes the static files automatically.

If your repository uses a different branch or folder, select the location that actually contains `index.html`.

### What works on GitHub Pages?

GitHub Pages serves static files such as HTML, CSS, JavaScript, and images. It **does not run Python Flask, SQLite, or Python/scikit-learn on the server**. The browser-only prototype may save information in `localStorage`, which is local to that browser and is not shared across devices; clearing browser site data may remove it.

## Option B — GitHub Pages frontend + separate Python backend

Choose this option if you want to keep the frontend on GitHub Pages but run the full system described in the paper.

1. Keep the HTML/CSS/JavaScript frontend in the GitHub repository and publish it with Option A.
2. Deploy the Flask application to a Python-capable hosting service that supports your app's runtime and persistent storage.
3. Configure the frontend's API/base URL to point to the deployed Flask backend.
4. Configure the backend's CORS policy to allow requests from your GitHub Pages website.
5. Confirm the backend's SQLite database is stored somewhere persistent and that it is writable by the application. Check the host's storage rules before relying on a local SQLite file.
6. Test prediction, nutrient lookup and scaling, food logging, daily goals, food-library management, and food suggestions on the live site.

**Important:** pushing the Flask files, SQLite database, or model to GitHub does not make them run on GitHub Pages. GitHub is the code repository; GitHub Pages is static hosting. The Python backend must run separately for the Flask + SQLite + scikit-learn implementation to work online.

## Which option should be used for the final demonstration?

- **Option A:** demonstrate the current browser-based prototype and describe it accurately as a static/browser-based version. Do not claim that it uses the live Flask backend or server-side SQLite database.
- **Option B:** use this if the final paper's implementation is the Flask + SQLite + TF-IDF/Logistic Regression version. Demonstrate only after the frontend and deployed backend are connected and the full workflow has been tested.

## Post-deployment checklist

- Open the published URL in a new tab and confirm the page loads.
- Test every navigation item and form.
- Add a food and refresh the page to check whether it persists.
- Change a goal and refresh to check whether it persists.
- Try a food name and check the predicted group; do not assume predictions are accurate without evaluation.
- Check the browser developer console for JavaScript errors.
- For Option B, also check the backend logs, API responses, CORS settings, and database persistence.

A successful GitHub Pages deployment confirms only that the static website was published. It does not verify that the Python backend, SQLite persistence, or machine-learning integration is working.
