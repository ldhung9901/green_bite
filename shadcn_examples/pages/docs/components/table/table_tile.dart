import 'package:docs/pages/docs/components_page.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class TableTile extends StatelessWidget implements IComponentPage {
  const TableTile({super.key});

  @override
  String get title => 'Table';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'table',
      title: 'Table',
      scale: 1.2,
      example: Card(
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: const Text('Name').bold()),
                    Expanded(flex: 2, child: const Text('Role').bold()),
                    Expanded(flex: 1, child: const Text('Status').bold()),
                  ],
                ),
              ),
              // Rows
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('John Doe')),
                    const Expanded(flex: 2, child: Text('Developer')),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Active',
                            style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Jane Smith')),
                    const Expanded(flex: 2, child: Text('Designer')),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Away',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(flex: 2, child: Text('Bob Johnson')),
                    const Expanded(flex: 2, child: Text('Manager')),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Active',
                            style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
