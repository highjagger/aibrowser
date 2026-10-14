FROM mcr.microsoft.com/playwright:v1.64.1-noble

# Install dependencies into /deps to avoid host bind-mount shadowing
WORKDIR /deps
COPY package.json ./
RUN npm install

# Set NODE_PATH so node can always locate packages from /deps/node_modules
ENV NODE_PATH=/deps/node_modules:/app/node_modules

# Setup application directory
WORKDIR /app
COPY . .
RUN mkdir -p /app/output

ENV HEADLESS=true
ENV BROWSER=firefox

CMD ["node", "automation.js"]
