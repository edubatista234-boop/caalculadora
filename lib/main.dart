import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const InvestmentComparatorApp());
}

// Configura o tema global e abre a tela onde o usuário informa os dados.
class InvestmentComparatorApp extends StatelessWidget {
  const InvestmentComparatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B5B);

    return MaterialApp(
      title: 'Comparador de investimentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
      ),
      home: const InvestmentFormPage(),
    );
  }
}

// Guarda os dados de um investimento e calcula seus totais a partir da evolução.
class Investment {
  const Investment({
    required this.name,
    required this.initialAmount,
    required this.monthlyContribution,
    required this.monthlyRate,
    required this.monthlyBalances,
  });

  final String name;
  final double initialAmount;
  final double monthlyContribution;
  final double monthlyRate;
  final List<double> monthlyBalances;

  double get finalAmount => monthlyBalances.last;

  double get totalEarnings =>
      finalAmount - initialAmount - monthlyContribution * monthlyBalances.length;
}

// Agrupa os dois investimentos e o período usado na simulação.
class InvestmentComparison {
  const InvestmentComparison({
    required this.first,
    required this.second,
    required this.months,
  });

  final Investment first;
  final Investment second;
  final int months;
}

class InvestmentFormPage extends StatefulWidget {
  const InvestmentFormPage({super.key});

  @override
  State<InvestmentFormPage> createState() => _InvestmentFormPageState();
}

class _InvestmentFormPageState extends State<InvestmentFormPage> {
  // O formulário valida todos os campos antes de iniciar os cálculos.
  final _formKey = GlobalKey<FormState>();

  // Controllers mantêm os valores digitados disponíveis para validação e cálculo.
  final _firstInitialController = TextEditingController();
  final _firstMonthlyController = TextEditingController();
  final _firstRateController = TextEditingController();
  final _secondInitialController = TextEditingController();
  final _secondMonthlyController = TextEditingController();
  final _secondRateController = TextEditingController();
  final _monthsController = TextEditingController();
  InvestmentComparison? _comparison;

  @override
  void dispose() {
    // Libera os recursos dos campos quando a tela de entrada é removida.
    _firstInitialController.dispose();
    _firstMonthlyController.dispose();
    _firstRateController.dispose();
    _secondInitialController.dispose();
    _secondMonthlyController.dispose();
    _secondRateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  // Validadores mostram ao usuário qual entrada precisa ser corrigida.
  String? _validateAmount(String? value) {
    final amount = value == null ? null : _parseAmount(value);
    if (amount == null || !amount.isFinite) {
      return 'Informe um valor válido.';
    }
    if (amount < 0) {
      return 'O valor não pode ser negativo.';
    }
    return null;
  }

  String? _validateRate(String? value) {
    final rate = value == null ? null : _parseAmount(value);
    if (rate == null || !rate.isFinite) {
      return 'Informe uma taxa válida.';
    }
    if (rate < 0) {
      return 'A taxa não pode ser negativa.';
    }
    return null;
  }

  String? _validateMonths(String? value) {
    final months = int.tryParse(value?.trim() ?? '');
    if (months == null || months <= 0) {
      return 'Informe um número de meses maior que zero.';
    }
    return null;
  }

  Investment _calculateInvestment({
    required String name,
    required double initialAmount,
    required double monthlyContribution,
    required double monthlyRate,
    required int months,
  }) {
    var balance = initialAmount;
    final balances = <double>[];

    // A cada mês, calcula os juros sobre o saldo e depois soma o aporte mensal.
    for (var month = 0; month < months; month++) {
      balance = balance * (1 + monthlyRate / 100) + monthlyContribution;
      if (!balance.isFinite) {
        throw const FormatException(
          'Os valores informados são muito altos para calcular.',
        );
      }
      balances.add(balance);
    }

    return Investment(
      name: name,
      initialAmount: initialAmount,
      monthlyContribution: monthlyContribution,
      monthlyRate: monthlyRate,
      monthlyBalances: balances,
    );
  }

  void _compareInvestments() {
    // Só calcula e navega quando todos os dados do formulário são válidos.
    if (!_formKey.currentState!.validate()) return;

    final months = int.parse(_monthsController.text.trim());
    try {
      final comparison = InvestmentComparison(
        first: _calculateInvestment(
          name: 'Investimento 1',
          initialAmount: _parseAmount(_firstInitialController.text)!,
          monthlyContribution: _parseAmount(_firstMonthlyController.text)!,
          monthlyRate: _parseAmount(_firstRateController.text)!,
          months: months,
        ),
        second: _calculateInvestment(
          name: 'Investimento 2',
          initialAmount: _parseAmount(_secondInitialController.text)!,
          monthlyContribution: _parseAmount(_secondMonthlyController.text)!,
          monthlyRate: _parseAmount(_secondRateController.text)!,
          months: months,
        ),
        months: months,
      );

      setState(() {
        _comparison = comparison;
      });
      // Envia os resultados para a página de comparação.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvestmentResultsPage(
            comparison: _comparison!,
            onRestart: _restart,
          ),
        ),
      );
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _restart() {
    // Limpa os campos e retorna à entrada para permitir uma nova simulação.
    setState(() {
      _comparison = null;
      _firstInitialController.clear();
      _firstMonthlyController.clear();
      _firstRateController.clear();
      _secondInitialController.clear();
      _secondMonthlyController.clear();
      _secondRateController.clear();
      _monthsController.clear();
    });
    Navigator.of(context).pop();
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    String? suffix,
    bool integerOnly = false,
  }) {
    // Campo reutilizável para valores monetários, taxas e período em meses.
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
      inputFormatters: integerOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: validator,
    );
  }

  Widget _investmentFields({
    required String title,
    required Color color,
    required TextEditingController initialController,
    required TextEditingController monthlyController,
    required TextEditingController rateController,
  }) {
    // Reúne os três dados específicos de cada investimento em um cartão.
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5EBE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(Icons.trending_up, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _numberField(
              label: 'Capital inicial',
              controller: initialController,
              validator: _validateAmount,
              suffix: 'R\$',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Aplicação mensal',
              controller: monthlyController,
              validator: _validateAmount,
              suffix: 'R\$',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Taxa de juros mensal',
              controller: rateController,
              validator: _validateRate,
              suffix: '%',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formulário rolável para caber em telas menores.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparador de investimentos'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Compare seus planos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Informe os valores e veja como cada investimento pode evoluir.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _investmentFields(
                    title: 'Investimento 1',
                    color: const Color(0xFF176B5B),
                    initialController: _firstInitialController,
                    monthlyController: _firstMonthlyController,
                    rateController: _firstRateController,
                  ),
                  const SizedBox(height: 12),
                  _investmentFields(
                    title: 'Investimento 2',
                    color: const Color(0xFF6C55B5),
                    initialController: _secondInitialController,
                    monthlyController: _secondMonthlyController,
                    rateController: _secondRateController,
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    label: 'Período da simulação',
                    controller: _monthsController,
                    validator: _validateMonths,
                    suffix: 'meses',
                    integerOnly: true,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _compareInvestments,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Comparar investimentos'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InvestmentResultsPage extends StatelessWidget {
  const InvestmentResultsPage({
    super.key,
    required this.comparison,
    required this.onRestart,
  });

  final InvestmentComparison comparison;
  final VoidCallback onRestart;

  // Mantém a apresentação dos valores monetários consistente nas duas páginas.
  String _currency(double value) => 'R\$ ${value.toStringAsFixed(2)}';

  // Cartão-resumo com o montante final e o rendimento acumulado.
  Widget _summaryCard(Investment investment, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5EBE8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      investment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Montante final', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _currency(investment.finalAmount),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rendimento total',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _currency(investment.totalEarnings),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Linha mensal com os dois saldos e barras proporcionais para comparação visual.
  Widget _evolutionRow(int month, double first, double second, double maxAmount) {
    final firstColor = const Color(0xFF176B5B);
    final secondColor = const Color(0xFF6C55B5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 54,
                child: Text('Mês $month', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(
                  _currency(first),
                  style: TextStyle(color: firstColor, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  _currency(second),
                  textAlign: TextAlign.end,
                  style: TextStyle(color: secondColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const SizedBox(width: 54),
              Expanded(
                child: LinearProgressIndicator(
                  value: (first / maxAmount).clamp(0.0, 1.0),
                  color: firstColor,
                  backgroundColor: firstColor.withValues(alpha: 0.12),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: (second / maxAmount).clamp(0.0, 1.0),
                  color: secondColor,
                  backgroundColor: secondColor.withValues(alpha: 0.12),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = comparison.first;
    final second = comparison.second;
    // Usa o maior saldo final como referência comum para as barras comparativas.
    final maxAmount = first.finalAmount > second.finalAmount
        ? first.finalAmount
        : second.finalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da comparação'),
        leading: IconButton(
          onPressed: onRestart,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Nova simulação',
        ),
        actions: [
          TextButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            label: const Text('Reiniciar'),
          ),
        ],
      ),
      body: SafeArea(
        // A lista permite consultar toda a evolução, mesmo em períodos longos.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Resumo após ${comparison.months} meses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryCard(first, const Color(0xFF176B5B)),
                const SizedBox(width: 8),
                _summaryCard(second, const Color(0xFF6C55B5)),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Evolução mensal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Montante acumulado (R\$) • barras proporcionais ao maior resultado',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE5EBE8)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Expanded(
                          child: Text(
                            'Investimento 1',
                            style: TextStyle(
                              color: const Color(0xFF176B5B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Investimento 2',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: const Color(0xFF6C55B5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    for (var index = 0; index < comparison.months; index++) ...[
                      _evolutionRow(
                        index + 1,
                        first.monthlyBalances[index],
                        second.monthlyBalances[index],
                        maxAmount,
                      ),
                      if (index < comparison.months - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cálculo estimado: os juros incidem mensalmente sobre o saldo, '
              'e a aplicação mensal é adicionada ao fim de cada mês. '
              'Não considera impostos ou taxas.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
