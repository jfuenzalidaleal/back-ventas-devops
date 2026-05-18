# ==========================================
# ETAPA 1: Compilación (Build Stage)
# ==========================================
FROM maven:3.8.8-eclipse-temurin-17-alpine AS builder

# Definir el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo de configuración de Maven (pom.xml)
COPY pom.xml .

# Descargar las dependencias para acelerar futuras compilaciones (Caché de Docker)
RUN mvn dependency:go-offline -B

# Copiar el código fuente del proyecto
COPY src ./src

# Compilar y empaquetar el proyecto saltándose las pruebas unitarias para agilizar el build
RUN mvn clean package -DskipTests

# ==========================================
# ETAPA 2: Ejecución (Run Stage)
# ==========================================
FROM eclipse-temurin:17-jre-alpine

# Aplicar principio de Mínimo Privilegio: Crear un usuario seguro del sistema
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar UNICAMENTE el archivo .jar generado en la etapa anterior
# Revisamos el pom.xml y el archivo compilado se llama comúnmente igual que el proyecto o se genera en /target
COPY --from=builder /app/target/*.jar app.jar

# Cambiar la propiedad de los archivos al usuario sin privilegios
RUN chown -R appuser:appgroup /app

# Cambiar al usuario no-root
USER appuser

# Exponer el puerto en el que corre tu aplicación Spring Boot (revisa tu application.properties, por defecto es 8080)
EXPOSE 8081

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]