FROM node:latest as builder

WORKDIR /app

COPY ./package.json ./package-lock.json ./

RUN npm install

COPY ./config-overrides.js ./tsconfig.json ./
COPY ./src ./src
COPY ./public ./public

RUN npm run build

FROM nginx:latest

COPY --from=builder /app/build /usr/share/nginx/html
