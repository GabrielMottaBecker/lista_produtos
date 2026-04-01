# ShopApp — CRUD Completo com Flutter

Aplicativo mobile desenvolvido em Flutter como atividade da disciplina **Desenvolvimento para Dispositivos Móveis II**.

O projeto consome a [FakeStore API](https://fakestoreapi.com/) e implementa o ciclo completo de operações **C.R.U.D** (Create, Read, Update, Delete) com **persistência local via SQLite**, seguindo uma arquitetura em camadas desacoplada.

---

## 📱 O que o app faz

| Operação | HTTP | Descrição |
|----------|------|-----------|
| **Read**   | GET    | Lista todos os produtos; exibe detalhes de cada item |
| **Create** | POST   | Cadastra novo produto via formulário |
| **Update** | PUT    | Edita produto existente via formulário pré-preenchido |
| **Delete** | DELETE | Remove produto com confirmação antes de excluir |

- **Persistência híbrida**: dados são buscados da API na primeira abertura e gravados no SQLite; nas sessões seguintes o app usa o banco local, tornando o funcionamento independente da conexão.
- **Sincronização manual**: botão "Sync" na tela de listagem força nova busca da API e atualiza o banco local.
- **Feedback visual**: indicadores de carregamento, SnackBars de sucesso/erro e diálogo de confirmação antes de excluir.

---

## 🗂️ Estrutura de pastas

```
lib/
├── core/
│   ├── errors/
│   │   └── failure.dart               # Classe de erro customizado
│   ├── network/
│   │   └── http_client.dart           # Cliente HTTP (GET, POST, PUT, DELETE)
│   └── routes/
│       └── app_routes.dart            # Constantes de rotas nomeadas
│
├── data/
│   ├── datasources/
│   │   ├── product_local_datasource.dart   # SQLite (sqflite)
│   │   └── product_remote_datasource.dart  # FakeStore API
│   ├── models/
│   │   └── product_model.dart         # fromJson / fromMap / toJson / toMap
│   └── repositories/
│       └── product_repository_impl.dart   # Repositório híbrido (API + SQLite)
│
├── domain/
│   ├── entities/
│   │   └── product.dart               # Entidade pura de domínio
│   └── repositories/
│       └── product_repository.dart    # Contrato (interface) do repositório
│
├── presentation/
│   ├── pages/
│   │   ├── home_page.dart             # Tela inicial com gradiente
│   │   ├── product_page.dart          # Listagem de produtos + FAB de criação
│   │   ├── product_detail_page.dart   # Detalhes + botões Editar e Excluir
│   │   └── product_form_page.dart     # Formulário reutilizado (criar / editar)
│   └── viewmodels/
│       ├── product_state.dart         # Estado reativo (ProductStatus enum)
│       └── product_viewmodel.dart     # Lógica de negócio + CRUD
│
└── main.dart                          # Injeção de dependências + rotas
```

---

## 🧭 Rotas

| Constante | Caminho | Tela |
|-----------|---------|------|
| `AppRoutes.home` | `/` | `HomePage` |
| `AppRoutes.products` | `/products` | `ProductPage` |
| `AppRoutes.productDetail` | `/products/detail` | `ProductDetailPage` |
| `AppRoutes.productCreate` | `/products/create` | `ProductFormPage` (cadastro) |
| `AppRoutes.productEdit` | `/products/edit` | `ProductFormPage` (edição) |

### Fluxo de navegação

```
HomePage
  └─► ProductPage  (listagem)
        ├─► ProductDetailPage  (detalhes)
        │     ├─► ProductFormPage  (edição via botão ✏️)
        │     └─► [delete com confirmação]
        └─► ProductFormPage  (cadastro via FAB ➕)
```

---

## 🏛️ Arquitetura

O projeto segue separação em três camadas:

```
Presentation (UI + ViewModel)
      │
      ▼
Domain (entidades + contratos)
      │
      ▼
Data (datasources + repositório)
      │
      ├── ProductRemoteDatasource  →  FakeStore API
      └── ProductLocalDatasource   →  SQLite (sqflite)
```

### Estratégia do repositório híbrido

```
getProducts()
  ├── Banco local tem dados?  →  retorna do SQLite
  └── Não  →  busca da API  →  salva no SQLite  →  retorna

createProduct()  →  POST na API  →  insere no SQLite  (fallback: só SQLite)
updateProduct()  →  PUT na API   →  atualiza SQLite   (fallback: só SQLite)
deleteProduct()  →  DELETE na API →  remove do SQLite
syncProducts()   →  limpa SQLite  →  busca API  →  popula SQLite
```

---

## 📦 Dependências

```yaml
dependencies:
  http: ^1.2.0       # Requisições HTTP
  sqflite: ^2.3.3+1  # Banco de dados SQLite local
  path: ^1.9.0       # Utilitário de caminhos para o banco
```

---

## ▶️ Como executar

```bash
# 1. Instale as dependências
flutter pub get

# 2. Execute o app (com dispositivo/emulador conectado)
flutter run
```

> **Nota:** Na primeira execução, o app busca os produtos da FakeStore API e os armazena no SQLite. As operações de escrita (POST/PUT/DELETE) são enviadas à API e sempre refletidas no banco local, garantindo consistência mesmo quando a API não persiste as mudanças permanentemente.

---

## 📝 Questões para reflexão (Atividade)

As respostas estão no arquivo **`RESPOSTAS.md`** na raiz do projeto.

---

## 👨‍💻 Autor

Projeto desenvolvido como atividade da disciplina **Desenvolvimento para Dispositivos Móveis II**.  
