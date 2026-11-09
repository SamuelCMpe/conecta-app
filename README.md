# Conecta (QR Conecta)

App en Flutter para compartir tu WhatsApp, Instagram, Facebook y otras redes **solo con quien escanea tu QR en persona**. Cada persona personaliza su perfil (foto, fondo, letra, botones, colores) y al escanear el QR de alguien ves su perfil con el diseño que eligió.

## Qué hace

- **Mi perfil:** nombre, usuario, ciudad, descripción, gustos, redes y un enlace destacado opcional.
- **Personalizar:** pestañas Datos, Fondo (imágenes, tu propia foto, degradados, patrones, oscurecer, desenfocar), Foto (forma y aro), Estilo (letra, botones, color de acento) y Redes (9 redes; escribes tu número, usuario o enlace y la app arma el enlace).
- **Mi QR:** el código cambia cada 30 segundos, así una foto o captura deja de servir. 4 estilos de QR.
- **Escanear:** con la cámara. Al escanear, ves el perfil de la otra persona y ella recibe el tuyo como solicitud.
- **Contactos:** aceptar o rechazar solicitudes, y quitar o devolver el acceso a tu perfil.

## Probarla rápido (modo demo, sin servidor)

```bash
flutter pub get
flutter run
```

Sin configurar Supabase la app arranca en **modo demo**: entras con cualquier correo y código, y hay contactos de ejemplo. En la pantalla Escanear aparece un botón "Simular escaneo".

## Conectar el servidor (Supabase)

1. Crea una cuenta y un proyecto gratis en [supabase.com](https://supabase.com).
2. En el proyecto ve a **SQL Editor → New query**, pega todo el archivo [`supabase/schema.sql`](supabase/schema.sql) y dale **Run**.
3. En **Authentication → Providers** deja activo **Email**. En **Authentication → Email Templates → Magic Link** agrega `{{ .Token }}` al mensaje para que llegue el código de 6 dígitos.
4. En **Project Settings → API** copia la *Project URL* y la *publishable key* (o *anon key*).
5. Ejecuta:

```bash
flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_KEY=TU_CLAVE
```

## Cómo funciona la privacidad

- Tu perfil solo lo pueden leer las personas que escanearon tu QR (regla en la base de datos, no solo en la app).
- El QR lleva un código aleatorio que caduca a los 40 segundos (30 visibles + 10 de margen).
- Al escanear a alguien, tu perfil le llega como **solicitud**: lo ve solo si lo acepta.
- Desde Contactos puedes quitarle el acceso a cualquiera en cualquier momento.
- Pendiente para más adelante: las fotos se guardan en una carpeta pública con nombres aleatorios; si quieres más privacidad se pueden servir con enlaces firmados.

## Estructura

```
lib/
  main.dart                  arranque (demo o Supabase)
  models/                    perfil, redes y cómo se arma cada enlace
  data/                      DemoRepository y SupabaseRepository
  state/app_state.dart       estado de la app
  theme/profile_look.dart    fondos, letras, botones y colores del perfil
  widgets/                   vista de perfil, avatar, vidrio
  screens/                   bienvenida, perfil, editor, mi QR, escáner, contactos
supabase/schema.sql          tablas, reglas de seguridad y funciones
assets/backgrounds/          fondos de ejemplo
```

## Pruebas

```bash
flutter analyze
flutter test
```

## Descargar el APK (Android)

Cada vez que se sube código a `main`, GitHub genera el APK solo (ver `.github/workflows/build-apk.yml`).
Se descarga desde **Releases → Última versión → conecta.apk**:
https://github.com/SamuelCMpe/conecta-app/releases/tag/ultima

Para instalarlo en Android tienes que permitir "instalar apps de origen desconocido" cuando el teléfono lo pida.
Si agregas los secretos `SUPABASE_URL` y `SUPABASE_KEY` en *Settings → Secrets and variables → Actions*, el APK usará tu servidor; si no, arranca en modo demo.
