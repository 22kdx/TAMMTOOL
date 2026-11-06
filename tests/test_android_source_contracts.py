"""Source/SQLite contract checks, not a substitute for Gradle/KAPT compilation.
Run with: python -m unittest discover -s tests -v
"""
import re
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class AndroidSourceContracts(unittest.TestCase):
    def test_hilt_entry_points_and_viewmodels(self):
        for app, package in [('marketer', 'marketerapp'), ('orders-delivery', 'ordersapp')]:
            root = ROOT / f'apps/{app}/app/src/main/java/com/tammtool/{package}'
            self.assertIn('@HiltAndroidApp', next((root / 'di').glob('*App.kt')).read_text())
            self.assertIn('@AndroidEntryPoint', (root / 'ui/MainActivity.kt').read_text())
            self.assertIn('hiltViewModel()', (root / 'ui/nav/AppNavGraph.kt').read_text())
            for path in (root / 'ui/viewmodel').glob('*.kt'):
                if path.name == 'BaseViewModel.kt':
                    continue
                with self.subTest(path=path):
                    self.assertIn('@HiltViewModel', path.read_text())
                    self.assertIn('@Inject constructor', path.read_text())

    def test_room_entities_indices_foreign_keys_and_queries(self):
        for app in ['marketer', 'orders-delivery']:
            root = next((ROOT / f'apps/{app}/app/src/main/java/com/tammtool').iterdir())
            connection = sqlite3.connect(':memory:')
            for path in (root / 'data/model').glob('*.kt'):
                text = path.read_text()
                with self.subTest(entity=path):
                    self.assertIn('@Entity', text)
                    self.assertIn('@PrimaryKey', text)
                    table = re.search(r'tableName = "([^"]+)"', text)[1]
                    columns = re.findall(r'@ColumnInfo\(name = "([^"]+)"\)', text)
                    self.assertTrue(columns)
                    for names in re.findall(r'(?:Index\(value|childColumns) = \[([^]]+)\]', text):
                        for name in re.findall(r'"([^"]+)"', names):
                            self.assertIn(name, columns)
                    connection.execute(f'CREATE TABLE "{table}" (' + ','.join(f'"{c}"' for c in columns) + ')')
            for path in (root / 'data/local').glob('*Dao.kt'):
                text = path.read_text()
                self.assertIn('@Dao', text)
                for match in re.finditer(r'@Query\((?:"""(.*?)"""|"([^"\n]*)")\)', text, re.S):
                    query = match[1] if match[1] is not None else match[2]
                    bindings = {name: 1 for name in re.findall(r':(\w+)', query)}
                    with self.subTest(dao=path, query=query):
                        connection.execute('EXPLAIN ' + query, bindings)
            connection.close()

    def test_repository_dao_method_names(self):
        for app in ['marketer', 'orders-delivery']:
            root = next((ROOT / f'apps/{app}/app/src/main/java/com/tammtool').iterdir())
            for path in (root / 'data/repository').glob('*.kt'):
                text = path.read_text()
                for instance, dao in re.findall(r'private val (\w+): (\w+Dao)', text):
                    declared = set(re.findall(r'fun (\w+)\(', (root / f'data/local/{dao}.kt').read_text()))
                    for method in re.findall(r'\b' + instance + r'\.(\w+)\(', text):
                        with self.subTest(repository=path, method=method):
                            self.assertIn(method, declared)


if __name__ == '__main__':
    unittest.main()
