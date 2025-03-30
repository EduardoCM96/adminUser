# Admin User App

Aplicación iOS para la gestión de usuarios con persistencia local y sincronización con API REST.

## Stack Tecnológico 🛠️

- **Lenguaje:** Swift
- **Arquitectura:** MVVM + Coordinator
- **UI Framework:** SwiftUI
- **Persistencia:** Realm
- **Networking:** Alamofire
- **Versiones iOS:** 15+
- **Idiomas:** Español e Inglés

## Características Principales ✨

### 1. Gestión de Usuarios
- Lista de usuarios desde API (https://jsonplaceholder.typicode.com/users)
- Visualización de detalles de usuario
- Creación de nuevos usuarios
- Edición de usuarios existentes
- Eliminación lógica de usuarios

### 2. Información de Usuario
- Nombre de usuario
- Nombre completo
- Teléfono
- Email
- Ciudad
- Imagen de perfil por defecto
- Ubicación geográfica (latitud/longitud)

### 3. Validaciones
- Validación de email
- Campos requeridos
- Validaciones reutilizables
- Manejo de errores robusto

### 4. Características Técnicas
- Concurrencia con Combine/async-await
- Integración con Core Location
- Manejo de permisos de ubicación
- Actualizaciones en segundo plano
- Persistencia local con Realm
- Sincronización con API

## Instalación 🔧

1. Clonar el repositorio:
```bash
git clone [URL_DEL_REPOSITORIO]
```

2. Navegar al directorio del proyecto:
```bash
cd adminUser
```

3. Instalar dependencias:
```bash
# Si usas Swift Package Manager (recomendado)
xed .

# Las dependencias se instalarán automáticamente al abrir el proyecto
```

## Estructura del Proyecto 📁

```
adminUser/
├── App/
│   └── adminUserApp.swift
├── Coordinators/
│   └── AppCoordinator.swift
├── Views/
│   ├── UserListView.swift
│   ├── UserDetailView.swift
│   └── CreateUserView.swift
├── ViewModels/
│   ├── UserListViewModel.swift
│   ├── UserDetailViewModel.swift
│   └── CreateUserViewModel.swift
├── Models/
│   └── User.swift
├── Services/
│   ├── APIService.swift
│   └── LocationService.swift
└── Utils/
    ├── ValidationManager.swift
    └── LocalizationManager.swift
```

## Características Detalladas 🔍

### Lista de Usuarios
- Visualización de usuarios desde API
- Información básica: username, nombre, teléfono, email, ciudad
- Navegación a detalles

### Detalle de Usuario
- Información completa del usuario
- Imagen de perfil por defecto
- Edición de nombre y email
- Persistencia local de cambios

### Creación de Usuario
- Formulario de creación con validaciones
- Campos: nombre, email, teléfono
- Captura de ubicación actual
- Validaciones en tiempo real

### Ubicación
- Integración con Core Location
- Manejo de permisos
- Captura de coordenadas
- Actualizaciones en segundo plano

### Persistencia
- Almacenamiento local con Realm
- Sincronización con API
- Eliminación lógica de registros

### Internacionalización
- Soporte para español e inglés
- Textos localizados
- Cambio dinámico de idioma

## Licencia 📄

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE.md](LICENSE.md) para detalles

## Autor ✒️

* **Eduardo Carranza Maqueda** - *Desarrollo Inicial* 