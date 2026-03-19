# lista_produtos

---

## Sobre o projeto

Esta atividade evolui a aplicação construída no repositório mobile_arquitetura_01, incorporando melhorias arquiteturais comuns em aplicações reais. A arquitetura em camadas é mantida e estendida com três novas funcionalidades:

- **Estado explícito da interface** — a UI representa claramente cada fase da operação
- **Tratamento de erros** — falhas de comunicação são capturadas e exibidas ao usuário
- **Cache local simples** — produtos carregados são armazenados em memória e utilizados como fallback quando a API não está disponível

Na evolução mais recente, o projeto passou a contar também com:

- **Navegação entre múltiplas telas** — fluxo completo com tela inicial, listagem e detalhes
- **Rotas nomeadas** — centralização das rotas em uma classe `AppRoutes`
- **Passagem de dados entre telas** — produto selecionado enviado como argumento de rota
- **Entidade e modelo ampliados** — campos de descrição, categoria e avaliação incorporados da API

---

## Questionário de Reflexão

### 1. Em qual camada foi implementado o mecanismo de cache? Explique por que essa decisão é adequada dentro da arquitetura proposta.

O cache foi implementado na camada **data**, mais especificamente em dois pontos: o `ProductLocalDatasource` é responsável por armazenar e recuperar os dados em memória, e o `ProductRepositoryImpl` é responsável pela **decisão** de quando usar o cache ou a API.

Essa decisão é adequada porque a camada `data` é exatamente onde ficam os detalhes de acesso a dados — sejam eles remotos ou locais. O domínio não precisa saber de onde os dados vêm; ele apenas declara que precisa de uma lista de produtos. A apresentação não precisa saber que existe um cache; ela apenas solicita os dados ao ViewModel. Ao centralizar essa lógica no repositório, o comportamento de fallback fica encapsulado em um único lugar, facilitando manutenção e testes.

---

### 2. Por que o ViewModel não deve realizar chamadas HTTP diretamente?

O ViewModel pertence à camada de apresentação, cujo papel é coordenar o estado da interface e reagir a eventos do usuário. Se ele realizasse chamadas HTTP diretamente, estaria acumulando responsabilidades que pertencem à camada de dados, violando o princípio de responsabilidade única.

Além disso, isso criaria um acoplamento forte entre a interface e a infraestrutura de rede. Trocar a API, adicionar cache ou modificar a estratégia de busca exigiria alterações diretas no ViewModel — e consequentemente na lógica que controla a interface. Mantendo o ViewModel dependente apenas do contrato abstrato `ProductRepository`, qualquer mudança na origem dos dados não afeta o comportamento da apresentação.

---

### 3. O que poderia acontecer se a interface acessasse diretamente o DataSource?

A interface passaria a conhecer detalhes técnicos de infraestrutura que não lhe dizem respeito, como o formato das requisições HTTP, os modelos de dados da API e o tratamento de exceções de rede. Isso tornaria o código da UI difícil de manter, pois qualquer mudança na API ou na estrutura dos dados exigiria alterações nos widgets.

Além disso, a lógica de negócio ficaria espalhada pela interface — como a decisão de usar cache em caso de falha —, tornando o sistema frágil e difícil de testar. A separação entre interface e acesso a dados existe exatamente para evitar esse tipo de acoplamento.

---

### 4. Como essa arquitetura facilitaria a substituição da API por um banco de dados local?

Como o domínio depende apenas da abstração `ProductRepository`, e não de nenhuma implementação concreta, bastaria criar uma nova implementação — por exemplo, `ProductLocalRepositoryImpl` — que busca dados de um banco de dados local como SQLite ou Hive, sem alterar nenhum código da camada de domínio ou apresentação.

O `main.dart` seria o único ponto de mudança: bastaria trocar qual implementação de `ProductRepository` é injetada. Toda a lógica de interface, estados e ViewModel permaneceria intacta. Esse é o benefício direto do Princípio da Inversão de Dependência aplicado à arquitetura em camadas.

---

### 5. Como a navegação com `Navigator.push()` e rotas nomeadas se relaciona com a arquitetura em camadas?

A navegação pertence exclusivamente à camada de apresentação. O uso de rotas nomeadas, centralizadas em `AppRoutes`, segue o mesmo princípio de encapsulamento aplicado às outras camadas: em vez de espalhar strings de rota pelos widgets, um único arquivo declara os contratos de navegação da aplicação.

A passagem de dados entre telas via `arguments` mantém o domínio desacoplado da navegação — a tela de detalhes recebe uma entidade `Product` já mapeada, sem precisar saber como ela foi obtida ou de onde veio. A lógica de carregamento continua no ViewModel; a decisão de para onde navegar continua nos widgets.

---

## Arquitetura

```
lib/
├── main.dart                                       # Entrada, injeção de dependências e rotas
│
├── core/
│   ├── errors/
│   │   └── failure.dart                            # Estrutura padronizada de erros
│   ├── network/
│   │   └── http_client.dart                        # Cliente HTTP com tratamento de exceções
│   └── routes/
│       └── app_routes.dart                         # Rotas nomeadas centralizadas (NOVO)
│
├── domain/
│   ├── entities/
│   │   └── product.dart                            # Entidade de domínio (ampliada)
│   └── repositories/
│       └── product_repository.dart                 # Contrato abstrato do repositório
│
├── data/
│   ├── models/
│   │   └── product_model.dart                      # DTO com fromJson e toEntity() (ampliado)
│   ├── datasources/
│   │   ├── product_remote_datasource.dart          # Requisição HTTP à API
│   │   └── product_local_datasource.dart           # Cache em memória
│   └── repositories/
│       └── product_repository_impl.dart            # Decide entre remoto e cache
│
└── presentation/
    ├── viewmodels/
    │   ├── product_state.dart                      # Estados explícitos da UI
    │   └── product_viewmodel.dart                  # Coordena estado e chamadas
    └── pages/
        ├── home_page.dart                          # Tela inicial (NOVO)
        ├── product_page.dart                       # Listagem de produtos (atualizada)
        └── product_detail_page.dart                # Detalhes do produto (NOVO)
```

---

## O que foi refatorado

### 1 — Estado explícito da interface

Foi criada a classe `ProductState` com um enum `ProductStatus` que representa os quatro estados possíveis da interface:

| Estado | Descrição |
|--------|-----------|
| `initial` | App recém aberto, sem dados |
| `loading` | Requisição em andamento |
| `success` | Dados carregados com sucesso |
| `error` | Falha na requisição e sem cache disponível |

A `ProductPage` usa `switch` sobre o estado atual para exibir o widget correto em cada situação.

### 2 — Tratamento de erros

O `HttpClient` passou a capturar exceções de rede (`SocketException`, timeout, erros de servidor) e convertê-las em `Failure`, uma estrutura padronizada definida na camada `core`. O `ProductRepositoryImpl` captura essas falhas e decide o próximo passo. O `ProductViewModel` atualiza o estado para `error` quando não há alternativa, e a `ProductPage` exibe a mensagem ao usuário com a opção de tentar novamente.

### 3 — Cache local simples

Foi adicionado o `ProductLocalDatasource`, responsável exclusivamente por armazenar e recuperar produtos em memória. A lógica de decisão fica no `ProductRepositoryImpl`:

```
1. Tenta buscar da API remota
2. Se sucesso → salva no cache e retorna os dados
3. Se falha → verifica se há cache disponível
   - Se há cache → retorna os dados em cache
   - Se não há cache → propaga o erro
```

### 4 — Navegação entre telas (NOVO)

A aplicação foi expandida de uma única tela para um fluxo de três telas com navegação encadeada:

```
HomePage  →  ProductPage  →  ProductDetailPage
```

A navegação utiliza `Navigator.pushNamed()` com rotas declaradas em `AppRoutes`. Os dados do produto selecionado são passados como `arguments` para a tela de detalhes, que os recupera via `ModalRoute.of(context)!.settings.arguments`.

### 5 — Rotas nomeadas centralizadas (NOVO)

Em vez de strings de rota espalhadas pelos widgets, foi criada a classe `AppRoutes` em `core/routes/`:

```dart
class AppRoutes {
  static const String home    = '/';
  static const String products = '/products';
  static const String productDetail = '/products/detail';
}
```

O `MaterialApp` em `main.dart` declara o mapa de rotas uma única vez, associando cada constante ao widget correspondente.

### 6 — Entidade e modelo ampliados (NOVO)

A entidade `Product` e o modelo `ProductModel` foram estendidos para incluir todos os campos relevantes retornados pela FakeStore API:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | `int` | Identificador do produto |
| `title` | `String` | Nome do produto |
| `price` | `double` | Preço |
| `image` | `String` | URL da imagem |
| `description` | `String` | Descrição completa *(novo)* |
| `category` | `String` | Categoria *(novo)* |
| `ratingRate` | `double` | Nota média *(novo)* |
| `ratingCount` | `int` | Número de avaliações *(novo)* |

O `ProductModel` passou a expor o método `toEntity()`, centralizando o mapeamento de modelo para entidade no próprio objeto.

---

## Fluxo de navegação

```
┌─────────────────────────────────┐
│           HomePage              │
│  Tela inicial com botão         │
│  "Ver Produtos"                 │
└──────────────┬──────────────────┘
               │ Navigator.pushNamed('/products')
               ▼
┌─────────────────────────────────┐
│          ProductPage            │
│  Lista produtos da API          │
│  Exibe: nome, preço,            │
│  categoria e avaliação          │
└──────────────┬──────────────────┘
               │ Navigator.pushNamed('/products/detail',
               │   arguments: product)
               ▼
┌─────────────────────────────────┐
│       ProductDetailPage         │
│  Exibe detalhes completos:      │
│  imagem, preço, descrição,      │
│  categoria, nota e avaliações   │
└─────────────────────────────────┘
```

Navegação de retorno: `Navigator.pop()` volta à tela anterior. O botão "Início" em qualquer tela usa `Navigator.pushNamedAndRemoveUntil()` para retornar à `HomePage` limpando a pilha de navegação.

---

## Regra de dependência

```
presentation  →  domain
data          →  domain
domain        →  nenhuma camada
core          →  nenhuma camada
```

A UI não acessa datasources diretamente. O ViewModel não faz HTTP. O Repository decide a origem dos dados. Os datasources executam apenas IO. A navegação permanece restrita à camada de apresentação.

---

## API utilizada

**Fake Store API**  
`GET https://fakestoreapi.com/products`

---

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e no PATH
- Dart SDK (incluído no Flutter)
- Chrome, Edge ou outro navegador suportado

```bash
flutter doctor
```

---

## Como rodar

**1. Clone o repositório**
```bash
git clone https://github.com/GabrielMottaBecker/lista_produtos.git
cd lista_produtos
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Execute**

Windows (requer Visual Studio com C++):
```bash
flutter run -d windows
```

Web:
```bash
flutter run -d chrome
flutter run -d edge
```

Se o navegador não abrir automaticamente:
```bash
flutter run -d web-server
```
Copie o endereço exibido (ex: `http://localhost:XXXXX`) e abra no navegador.

---

## Como usar o app

- Ao abrir, a **tela inicial** é exibida com o botão "Ver Produtos"
- Clique no botão para navegar à **tela de listagem**
- Os produtos são carregados automaticamente da API com indicador de carregamento
- Cada card exibe nome, preço, categoria e avaliação do produto
- Clique em um produto para abrir a **tela de detalhes**
- Na tela de detalhes, são exibidos: imagem ampliada, preço em destaque, descrição completa, categoria, nota e número de avaliações
- Use o botão de voltar (←) para retornar à tela anterior
- Use o ícone de casa (⌂) para voltar diretamente à tela inicial de qualquer ponto da aplicação
- Se a API falhar e houver produtos em cache, o app exibe os dados salvos anteriormente
- Se a API falhar sem cache, é exibida uma mensagem de erro com botão para tentar novamente

---

## Dependências

| Pacote | Versão | Uso |
|--------|--------|-----|
| `flutter` | SDK | Framework principal |
| `http` | ^1.2.0 | Requisições HTTP |
| `cupertino_icons` | ^1.0.8 | Ícones iOS |

---

## Autor

Desenvolvido como atividade acadêmica para a disciplina **Desenvolvimento para Dispositivos Móveis II**.
