<p align="right">
  <a href="./README.md">English</a> |
  <a href="./ID.md">Bahasa Indonesia</a>
</p>

## Workflow Setup

When you run `GitActionServer.sh` or `GitActionServer.bat`, the generator creates the following workflow file in your repository:

```text
.github/
└── workflows/
    └── gitactionserver.yml
```

# GitActionServer

Generator workflow GitHub Actions untuk menyiapkan lingkungan CLI/Desktop,
memilih kategori aplikasi, menjalankan Docker, dan mencadangkan data ke
repository yang sama.

## Struktur

```text
GitActionServer/
├── GitActionServer.sh
├── GitActionServer.bat
└── README.md
```

## Persyaratan

- Repository GitHub.
- Git.
- Git Bash untuk menjalankan file BAT.
- GitHub Actions diaktifkan.
- Izin repository untuk commit dan push.

## Instalasi

### Linux atau macOS

```bash
chmod +x GitActionServer.sh
./GitActionServer.sh
```

Jalankan dari dalam repository Git.

### Windows

Jalankan `GitActionServer.bat` dari folder repository.
Git for Windows harus terpasang.

## Menjalankan workflow

1. Commit dan push file generator serta workflow yang dihasilkan.
2. Buka repository di GitHub.
3. Pilih tab Actions.
4. Pilih workflow GitActionServer.
5. Klik Run workflow.
6. Pilih OS, mode lingkungan, Docker image, kategori aplikasi,
   dan interval backup.

## Folder backupPush

Folder sumber backup dibuat pada HOME lingkungan yang berjalan:

- Linux: `$HOME/backupPush`
- macOS: `$HOME/backupPush`
- Windows: `$HOME/backupPush` dalam lingkungan Bash

Isi folder tersebut disinkronkan ke `backupPush/` di root repository.

Semua file di dalam folder dicadangkan, termasuk file tersembunyi.
Setiap folder bernama `node_modules` dikecualikan pada semua tingkat.

## Interval backup

Workflow memeriksa jadwal setiap jam. Interval 1 sampai 5 jam menentukan
jam pemeriksaan mana yang menjalankan backup.

Jadwal GitHub Actions menggunakan UTC. Jadwal dapat tertunda oleh GitHub,
dan bukan jaminan eksekusi tepat pada menit tertentu.

## Batasan penting

- GitHub-hosted runner bersifat sementara. Data yang dibuat di luar
  `backupPush` tidak otomatis bertahan setelah job selesai.
- Folder `backupPush` dipulihkan dari repository sebelum proses backup.
- Docker container yang digunakan workflow bersifat sementara.
- Pilihan desktop pada template ini memasang atau menandai komponen
  desktop, tetapi tidak menyediakan koneksi desktop jarak jauh siap pakai.
  Akses jarak jauh membutuhkan konfigurasi tambahan yang aman.
- Untuk lingkungan yang harus hidup terus-menerus, gunakan self-hosted
  runner atau server sendiri.
- GitHub Actions memerlukan izin `contents: write` agar dapat melakukan
  commit dan push.
- Branch protection dapat menolak push langsung.
- File rahasia di `backupPush` akan ikut masuk ke riwayat Git. Repository
  private tidak menghilangkan risiko jika akun atau token bocor.

## Pengembangan

Generator ini sengaja menggunakan tiga file sumber. Workflow yang
dihasilkan ditempatkan di `.github/workflows/gitactionserver.yml`.
