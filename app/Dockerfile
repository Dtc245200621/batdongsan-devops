FROM node:20-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .
RUN chown -R node:node /usr/src/app
USER node
EXPOSE 3000
CMD ["node", "server.js"]
