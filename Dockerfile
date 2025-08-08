FROM node:18-alpine

WORKDIR /app
COPY app.js .

# Add curl installation here
RUN apk add --no-cache curl

CMD [ "node", "app.js" ]