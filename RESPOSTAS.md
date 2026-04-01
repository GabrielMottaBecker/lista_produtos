# Questionários de Reflexão — Flutter

---

## Atividade 05 — Arquitetura em Camadas

**1. Em qual camada foi implementado o mecanismo de cache? Por que?**

Na camada `data`, em dois pontos: o `ProductLocalDatasource` armazena e recupera dados em memória, e o `ProductRepositoryImpl` decide quando usar o cache ou a API. Essa decisão é adequada porque o domínio não precisa saber de onde os dados vêm, e a lógica de fallback fica encapsulada em um único lugar, facilitando manutenção e testes.

---

**2. Por que o ViewModel não deve realizar chamadas HTTP diretamente?**

Porque o ViewModel pertence à camada de apresentação e acumular responsabilidades de infraestrutura violaria o princípio de responsabilidade única. Mantendo-o dependente apenas do contrato abstrato `ProductRepository`, qualquer mudança na origem dos dados não afeta a apresentação.

---

**3. O que poderia acontecer se a interface acessasse diretamente o DataSource?**

A UI passaria a conhecer detalhes técnicos como formato de requisições HTTP e modelos da API. A lógica de negócio ficaria espalhada pelos widgets, tornando o sistema frágil, difícil de manter e de testar.

---

**4. Como essa arquitetura facilitaria a substituição da API por um banco de dados local?**

Bastaria criar uma nova implementação de `ProductRepository` (ex: `ProductLocalRepositoryImpl`) que lê de SQLite ou Hive. O único ponto de mudança seria o `main.dart`, onde a implementação é injetada — todo o restante (domínio, ViewModel, interface) permaneceria intacto.

---

**5. Como a navegação com `Navigator.push()` e rotas nomeadas se relaciona com a arquitetura em camadas?**

A navegação pertence exclusivamente à camada de apresentação. Centralizar as rotas em `AppRoutes` evita strings espalhadas pelos widgets. A tela de detalhes recebe uma entidade `Product` já mapeada, sem precisar saber como foi obtida, mantendo o domínio desacoplado da navegação.

---

## Atividade 06/07 — Gerenciamento de Estado

**1. O que significa gerenciamento de estado em uma aplicação Flutter?**

É controlar quais dados a aplicação mantém em memória e garantir que a interface os reflita automaticamente sempre que mudam. Estado é qualquer informação que pode mudar em tempo de execução, como se um produto está favoritado ou não.

---

**2. Por que manter o estado diretamente nos widgets pode gerar problemas?**

O estado fica preso no widget que o criou. Se outro widget precisar do mesmo dado, é necessário passá-lo por vários níveis da árvore via parâmetros (*prop drilling*), tornando o código difícil de manter e propenso a inconsistências.

---

**3. Qual é o papel do `notifyListeners()` no Provider?**

Avisa todos os widgets que estão ouvindo o provider que algo mudou. O Flutter reconstrói automaticamente apenas os widgets registrados com `Consumer` ou `context.watch`, atualizando a interface sem intervenção manual.

---

**4. Qual é a principal diferença conceitual entre Provider e Riverpod?**

O Provider depende da árvore de widgets — o estado precisa estar registrado acima dos consumidores. O Riverpod é independente da árvore: os providers são globais, acessíveis de qualquer lugar, e oferecem melhor segurança em tempo de compilação.

---

**5. No padrão BLoC, por que a interface não altera diretamente o estado?**

Porque ela apenas dispara eventos; quem decide como o estado muda é o BLoC. Isso separa completamente a lógica de negócio da apresentação, tornando o comportamento previsível e testável independentemente da interface.

---

**6. Qual a vantagem de organizar o fluxo `Evento → Bloc → Novo estado → Interface`?**

Cada mudança de estado tem uma causa rastreável (o evento) e passa por um ponto centralizado (o BLoC). Isso facilita depuração, testes unitários e manutenção, pois a lógica nunca está espalhada pelos widgets.

---

**7. Qual estratégia de gerenciamento de estado foi utilizada?**

Provider, com um `ChangeNotifier` centralizado (`ProductProvider`) registrado no topo da árvore via `ChangeNotifierProvider` e consumido com `Consumer` nos widgets.

---

**8. Quais foram as principais dificuldades encontradas?**

Entender o escopo correto do `Consumer`: muito alto na árvore reconstrói widgets desnecessários; muito baixo deixa partes da tela desatualizadas. No filtro de favoritos, foi necessário operar sempre sobre a lista original para evitar inconsistência de índices.

---

## Atividade 08 — Navegação entre Telas

**1. Qual era a estrutura do projeto antes das novas telas?**

Apenas uma tela (`ProductPage`) como ponto de entrada, com um botão para carregar produtos da API. Sem navegação entre páginas e sem tela de detalhes.

---

**2. Como ficou o fluxo após a implementação da navegação?**

```
HomePage → ProductPage → ProductDetailPage
```

---

**3. Qual é o papel do `Navigator.push()`?**

Empilha uma nova tela sobre a atual, usado para avançar no fluxo (ex: abrir detalhes de um produto).

---

**4. Qual é o papel do `Navigator.pop()`?**

Remove a tela atual da pilha, retornando à anterior. Acionado pelo botão de voltar.

---

**5. Como os dados do produto foram enviados para a tela de detalhes?**

Via parâmetro `arguments` do `Navigator.pushNamed()`, passando o objeto `Product` completo e recuperando na tela destino com `ModalRoute.of(context)!.settings.arguments`.

---

**6. Por que a tela de detalhes depende das informações da tela anterior?**

Porque ela não faz requisição própria — apenas exibe o objeto recebido, evitando uma segunda chamada desnecessária à API.

---

**7. Quais foram as principais mudanças no projeto?**

Criação de `HomePage` e `ProductDetailPage`, adição de rotas nomeadas em `AppRoutes`, atualização do `main.dart`, ampliação da entidade `Product` com descrição, categoria e avaliação, e atualização do README.

---

**8. Qual foi a principal dificuldade na adaptação para múltiplas telas?**

Garantir que a entidade `Product` tivesse todos os campos necessários antes de implementar a `ProductDetailPage`. Foi preciso ampliar o modelo, atualizar o `fromJson()` e só então construir a tela — qualquer ordem diferente exigiria refatoração no meio da implementação.

---

## Atividade 09 — Evolução do Projeto (C.R.U.D)

**1. Quais eram as limitações da versão inicial?**

Restrita apenas a operações de leitura (GET). Não havia tela de detalhes completa, o cache em memória era volátil (perdido ao fechar o app) e o repositório implementava apenas `getProducts()`, sem suporte a criação, edição ou exclusão.

---

**2. Quais mudanças estruturais foram realizadas?**

- **Entidade `Product`**: `id` opcional (`int?`), adição de `toMap()`, `toJson()` e `copyWith()`.
- **`ProductModel`**: métodos `fromMap()`, `toMap()`, `toJson()` e `fromEntity()`.
- **`HttpClient`**: expandido com `post()`, `put()` e `delete()`.
- **`ProductLocalDatasource`**: substituído o cache em memória por **SQLite** via `sqflite`.
- **`ProductRepository`** e **`ProductRepositoryImpl`**: suporte completo a CRUD com fallback local.
- **`ProductViewModel`**: adicionados `createProduct()`, `updateProduct()`, `deleteProduct()` e `syncProducts()`.
- **Novas telas**: `ProductFormPage` (formulário reutilizável) e `ProductDetailPage` com ações de editar e excluir.

---

**3. Como ficou o fluxo de navegação?**

```
HomePage
  └─► ProductPage  (listagem + FAB para criar)
        ├─► ProductDetailPage  (detalhes)
        │     ├─► ProductFormPage  (edição)
        │     └─► Diálogo de confirmação  (exclusão)
        └─► ProductFormPage  (cadastro)
```

---

**4. Quais atributos passaram a ser utilizados?**

| Atributo | Tipo | Uso |
|---|---|---|
| `id` | `int?` | Identificação para PUT/DELETE |
| `title` | `String` | Listagem, detalhes e formulário |
| `price` | `double` | Listagem, detalhes e formulário |
| `description` | `String` | Detalhes e formulário |
| `category` | `String` | Badge na listagem, detalhes e formulário |
| `image` | `String` | Todas as telas; preview no formulário |
| `ratingRate` | `double` | Badge de avaliação |
| `ratingCount` | `int` | Contagem de avaliações |

---

**5. Como foi organizada a camada de acesso a dados?**

Padrão Repository com duas fontes:

```
ProductRepository (interface — domínio)
        │
        ▼
ProductRepositoryImpl
    ├── ProductRemoteDatasource  →  FakeStore API via HttpClient
    └── ProductLocalDatasource   →  SQLite via sqflite
```

`getProducts()` prefere o banco local; operações de escrita enviam à API e sincronizam o resultado no banco. Em caso de falha remota, a operação é registrada localmente (fallback).

---

**6. O projeto foi preparado para operações além do GET?**

Sim. Foram implementados todos os métodos HTTP:

- **GET**: `getProducts()` e `getProductById()`.
- **POST**: cadastro via formulário, enviado à API e persistido localmente.
- **PUT**: atualização completa identificada pelo `id` na URL.
- **DELETE**: remoção na API e no banco local, com confirmação do usuário.

---

**7. Houve uso de persistência local? Justifique.**

Sim, via **SQLite** (`sqflite`). A FakeStore API não persiste dados entre sessões, então sem banco local o usuário perderia tudo ao reabrir o app. A estratégia híbrida garante consistência: na primeira execução busca da API e grava no SQLite; nas seguintes lê do banco local; todas as escritas são refletidas imediatamente no banco. O botão "Sync" permite forçar nova sincronização quando necessário.

---

**8. Quais foram as principais dificuldades?**

1. **Compatibilidade do `id`**: a FakeStore sempre retorna `id: 21` para criação; foi necessário usar o ID gerado pelo SQLite como identificador local confiável.
2. **Passagem de argumentos**: migração de `arguments: product` para `arguments: {'product': product, 'viewModel': vm}` ao adicionar ações de edição/exclusão na `ProductDetailPage`.
3. **Formulário reutilizável**: lidar com estado inicial condicional (campos vazios vs. pré-preenchidos) e lógica de submissão diferente para criar e editar.
4. **Inicialização assíncrona do SQLite**: implementado padrão Singleton com getter `async` para garantir inicialização única e segura.
5. **Atualização da interface**: após operações CRUD, o ViewModel atualiza diretamente a lista em memória do `ValueNotifier<ProductState>`, proporcionando feedback imediato sem recarregar tudo da API.
