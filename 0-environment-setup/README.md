# Architettura e Utilizzo dell'Ambiente di Esempio

Questa directory contiene tutto il necessario per preparare un ambiente virtuale su cui eseguire esercitazioni Kubernetes in locale.

## Struttura dell'Ambiente

- **debian-cloud-image-*.qcow2**: Immagine base Debian per la creazione delle VM.
- **0-install-prerequisites.sh**: Script per installare i prerequisiti sul sistema host (es. qemu, libvirt, ansible).
- **1-net-common.sh**: Configura la rete virtuale comune per le VM.
- **2-dns.sh**: Prepara e avvia un server DNS locale per la risoluzione dei nomi tra le VM.
- **3-start-vms.sh**: Avvia le VM necessarie per il laboratorio.
- **4-stop-and-clean.sh**: Ferma e rimuove le VM e le risorse di rete create.
- **lib-start-vm.sh**: Libreria di funzioni per la gestione delle VM.
- **Makefile**: Comandi rapidi per le operazioni comuni (build, start, clean, ecc.).
- **run-ansible.sh**: Script per eseguire i playbook Ansible sulle VM avviate.
- **README.md**: Questo file di spiegazione.

## Utilizzo tramite Makefile

Per semplificare la gestione dell'ambiente, puoi utilizzare direttamente i comandi del `Makefile`:

- **make up**: Prepara l'immagine cloud Debian, configura la rete e il DNS, e avvia le VM necessarie per il laboratorio. Puoi specificare il numero di nodi con `make up N_NODES=3`.

- **make down**: Ferma e rimuove tutte le VM e le risorse di rete create.

- **make logs**: Visualizza i log di sistema delle VM e del servizio DNS per il debug.

- **make restart**: Esegue una pulizia completa e riavvia l'ambiente (`down` seguito da `up`).

- **make debian-cloud-image**: Scarica l'immagine cloud Debian e crea il symlink necessario.

- **make remove-old-cloud-images**: Rimuove le vecchie immagini cloud Debian dalla directory.

Questi comandi permettono di gestire l'intero ciclo di vita dell'ambiente di laboratorio in modo semplice e riproducibile, senza dover eseguire manualmente gli script.

## Note

- Tutti gli script sono pensati per essere eseguiti su Fedora Linux 42+.
- È necessario avere i permessi di amministratore per alcune operazioni (es. creazione rete, avvio VM).
- L'ambiente è pensato per essere riproducibile e facilmente resettabile.

## Supporto

Per dubbi o problemi, consultare le lezioni o chiedere al docente.
