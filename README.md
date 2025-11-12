## elm-poker — Local Test Instructions

### Prerequisites

-   Node.js and npm installed

### 1) Install the SPA static server

```bash
npm install http-server-spa -g
```

### 2) Build or watch the app

```bash
npm run build
```

```bash
npm run watch
```

### 3) Serve the built files

```bash
http-server-spa dist/
```

This will start a local server that serves the `dist/` directory with SPA routing. Open the printed URL in your browser (commonly `http://127.0.0.1:8080`).
