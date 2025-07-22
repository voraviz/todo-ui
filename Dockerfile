# Kubernetes-optimized Dockerfile for Vue.js application
FROM nginx:alpine

# Create a non-root user for Kubernetes with home directory
RUN addgroup -g 1001 -S appuser && \
    adduser -S -D -u 1001 -s /sbin/nologin -G appuser -h /home/appuser appuser

# Copy your application files directly
COPY . /usr/share/nginx/html

# Ensure index.html is the main file
RUN if [ -f /usr/share/nginx/html/index.html ]; then \
        echo "index.html found"; \
    else \
        echo "ERROR: index.html not found in the current directory"; \
        exit 1; \
    fi

# Create nginx configuration for Vue.js SPA running on port 8080 (non-privileged)
RUN echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen 8080;' >> /etc/nginx/conf.d/default.conf && \
    echo '    server_name localhost;' >> /etc/nginx/conf.d/default.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    index index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / {' >> /etc/nginx/conf.d/default.conf && \
    echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '    # Handle JS and CSS files' >> /etc/nginx/conf.d/default.conf && \
    echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {' >> /etc/nginx/conf.d/default.conf && \
    echo '        expires 1y;' >> /etc/nginx/conf.d/default.conf && \
    echo '        add_header Cache-Control "public, immutable";' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '    error_page 404 /index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf

# Remove default nginx page and Dockerfile from html directory
RUN rm -f /usr/share/nginx/html/index.html.orig && \
    rm -f /usr/share/nginx/html/Dockerfile

# Create necessary directories and set permissions for non-root user
RUN mkdir -p /home/appuser/client_temp && \
    mkdir -p /home/appuser/proxy_temp && \
    mkdir -p /home/appuser/fastcgi_temp && \
    mkdir -p /home/appuser/uwsgi_temp && \
    mkdir -p /home/appuser/scgi_temp && \
    chown -R appuser:appuser /usr/share/nginx/html && \
    chown -R appuser:appuser /etc/nginx/conf.d && \
    chown appuser:appuser /etc/nginx/nginx.conf && \
    chown -R appuser:appuser /home/appuser && \
    chmod -R 755 /home/appuser

# Create custom nginx.conf for non-root user with stdout/stderr logging
RUN echo 'worker_processes auto;' > /tmp/nginx.conf && \
    echo 'error_log /dev/stderr warn;' >> /tmp/nginx.conf && \
    echo 'pid /tmp/nginx.pid;' >> /tmp/nginx.conf && \
    echo 'events {' >> /tmp/nginx.conf && \
    echo '    worker_connections 1024;' >> /tmp/nginx.conf && \
    echo '}' >> /tmp/nginx.conf && \
    echo 'http {' >> /tmp/nginx.conf && \
    echo '    include /etc/nginx/mime.types;' >> /tmp/nginx.conf && \
    echo '    default_type application/octet-stream;' >> /tmp/nginx.conf && \
    echo '    sendfile on;' >> /tmp/nginx.conf && \
    echo '    keepalive_timeout 65;' >> /tmp/nginx.conf && \
    echo '    access_log /dev/stdout;' >> /tmp/nginx.conf && \
    echo '    client_body_temp_path /home/appuser/client_temp;' >> /tmp/nginx.conf && \
    echo '    proxy_temp_path /home/appuser/proxy_temp;' >> /tmp/nginx.conf && \
    echo '    fastcgi_temp_path /home/appuser/fastcgi_temp;' >> /tmp/nginx.conf && \
    echo '    uwsgi_temp_path /home/appuser/uwsgi_temp;' >> /tmp/nginx.conf && \
    echo '    scgi_temp_path /home/appuser/scgi_temp;' >> /tmp/nginx.conf && \
    echo '    include /etc/nginx/conf.d/*.conf;' >> /tmp/nginx.conf && \
    echo '}' >> /tmp/nginx.conf && \
    mv /tmp/nginx.conf /etc/nginx/nginx.conf

# Switch to non-root user
USER appuser

# Expose port 8080 (non-privileged port)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]