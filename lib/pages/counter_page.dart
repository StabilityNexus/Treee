import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_planting_protocol/providers/counter_provider.dart';
import 'package:tree_planting_protocol/widgets/basic_scaffold.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "Counter Page",
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "This is the counter page.",
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 20),
          Consumer<CounterProvider>(builder: (ctx, _, __) {
            return Text(
                'Counter: ${Provider.of<CounterProvider>(ctx, listen: true).getCount()}',
                style: const TextStyle(fontSize: 24));
          }),
          ElevatedButton(
            onPressed: () {
              Provider.of<CounterProvider>(context, listen: false).increment();
            },
            child: const Text("Increment Counter",
                style: TextStyle(fontSize: 20, color: Colors.white)),
          )
        ],
      )),
    );
  }
}
