📄 Documentação Técnica: Smart Contract BankV8
1. Visão Geral
O BankV8 é um Smart Contract focado em serviços financeiros descentralizados. Ele opera como uma plataforma híbrida que combina um Banco Tradicional (depósitos, saques e cobrança de taxas) e uma DEX (Corretora Descentralizada) básica para troca de tokens nativos (POL) por um token ERC-20 específico.

O contrato foi construído focando em segurança, eficiência de gás e escalabilidade modular, utilizando o padrão de atualização UUPS (Universal Upgradeable Proxy Standard).

2. Arquitetura e Padrões de Segurança
Padrão de Proxy: UUPS (UUPSUpgradeable).

Controle de Acesso: OwnableUpgradeable (Apenas o dono pode fazer upgrades e gerenciar configurações críticas).

Eficiência de Gás: Uso exclusivo de Custom Errors ao invés de require com strings.

Prevenção de Reentrância: Modificador customizado nonReentrant operando com a variável de estado _status (1 = Livre, 2 = Ocupado).

Interação com Tokens: Uso da biblioteca SafeERC20 da OpenZeppelin para garantir compatibilidade e segurança em transferências de tokens que não retornam booleanos perfeitamente.

Prevenção de Colisão de Storage: Inclusão da variável uint256[50] private __gap no final do contrato para blindar o estado durante futuros upgrades.

3. Módulos e Funcionalidades Principais
Módulo 1: Integração e Conformidade (KYC & AML)
Antes de realizar qualquer transação financeira, o usuário precisa ser validado pelo contrato.

registerRequest(nome, idade, país): Sistema de KYC (Know Your Customer). Registra os dados do usuário. Possui regra de negócio rígida: apenas maiores de 18 anos são aceitos. Ao passar, o usuário entra na Whitelist.

blockAccount(address) / approveAccount(address): Ferramentas de AML (Anti-Money Laundering) exclusivas do Admin para congelar contas suspeitas (Ficha Suja) ou reativá-las.

Módulo 2: Conta Corrente (Banco)
Serviços bancários para a moeda nativa da rede (POL).

deposit(): Função payable que permite a usuários registrados (VIPs) depositarem fundos no cofre do banco.

withdraw(valor): Permite o saque do saldo. Atenção: Uma taxa configurável (withdrawFee) é deduzida automaticamente do valor sacado e enviada para a tesouraria do banco.

getAccountBalance(address): Função de leitura do saldo bancário do usuário.

Módulo 3: Câmbio e Liquidez (DEX)
Sistema de conversão rápida (Swap) entre a moeda nativa (POL) e o Token ERC-20 oficial do banco.

buyToken(): Função payable onde o usuário envia POL e recebe o Token ERC-20. O cálculo obedece à taxa feeExchange (POL enviado × feeExchange = Tokens recebidos).

sellToken(quantidade): O usuário vende Tokens ERC-20 de volta para o contrato e recebe POL (Quantidade de Tokens ÷ feeExchange = POL recebido). Requer aprovação (approve) prévia do token no front-end.

Mecânica de Proteção: Ambas as funções checam antecipadamente se o contrato possui liquidez suficiente (liquidityPOL ou estoque de tokens) antes de executar a transação, evitando falhas silenciosas.

Módulo 4: Administração e Tesouraria (Admin)
Controles absolutos do Owner do contrato para gerir o negócio e proteger os fundos.

Botão de Pânico (Circuit Breaker): breakContract() e unBreakContract() ativam o estado de Pausa, travando todas as funções que possuem o modificador whenNotPaused (saques, depósitos, swaps) em caso de suspeita de ataque.

Gestão de Taxas: updateWithdrawFee() (limite de proteção até 10000 BPS / 100%) e updateFeeExchange() (evita divisão por zero).

Gestão da Pool (DEX): addLiquidityPOL, addLiquidityToken, removeLiquidityPOL e removeLiquidityToken permitem ao dono abastecer ou retirar o caixa da corretora.

Saque de Lucros: withdrawFeeAdmin() transfere todas as taxas de saque acumuladas pelos clientes (totalWithdrawFeeCollected) direto para a carteira do administrador.

Módulo 5: Upgradeability (Atualizações)
_authorizeUpgrade(): Função interna obrigatória no padrão UUPS. Protegida pelo onlyOwner, ela dita quem tem o poder de migrar a lógica do V8 para uma futura implementação V9.

4. Eventos Disparados (Logs)
O contrato emite eventos para facilitar a indexação de dados pelo Front-end (dApp) e por exploradores de blocos:

Transações Bancárias: DepositMade, WithdrawMade

Gestão de Taxas: WithdrawFeeUpdated, FeeExchangeUpdated

Atividades da DEX: TokenBuy, TokenSell, LiquidityPolAdd, LiquidityTokenAdd

Segurança: Paused, Unpaused