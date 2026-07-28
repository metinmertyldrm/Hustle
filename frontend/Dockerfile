FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html styles.css app.js manifest.webmanifest service-worker.js /usr/share/nginx/html/
COPY icons /usr/share/nginx/html/icons

EXPOSE 80
