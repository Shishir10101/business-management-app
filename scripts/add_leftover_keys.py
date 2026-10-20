#!/usr/bin/env python3
"""Adds the leftover Phase-11 ARB keys (en + ne, in parity).

Idempotent: a key already present in either file is skipped, so re-running
is safe. Mirrors scripts/add_phase11_keys.py.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN = os.path.join(ROOT, 'apps/mobile/lib/l10n/app_en.arb')
NE = os.path.join(ROOT, 'apps/mobile/lib/l10n/app_ne.arb')

NEW = {
    'showingAll': ('Showing all', 'सबै देखाइँदै'),
    'saveChanges': ('Save changes', 'परिवर्तन सुरक्षित गर्नुहोस्'),
    'supplierKhata': ('Supplier khata', 'आपूर्तिकर्ता खाता'),
    'applyToBill': ('Apply to bill', 'खरिद बिलमा लागू गर्नुहोस्'),
    'newMethod': ('New method', 'नयाँ भुक्तानी विधि'),
    'syncNow': ('Sync now', 'अहिले सिङ्क गर्नुहोस्'),
}


def load(path):
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)


def save(path, data):
    with open(path, 'w', encoding='utf-8') as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write('\n')


def main():
    en, ne = load(EN), load(NE)
    added = []
    for key, (en_val, ne_val) in NEW.items():
        if key in en or key in ne:
            print(f'skip {key} (already present)')
            continue
        en[key] = en_val
        ne[key] = ne_val
        added.append(key)
    if added:
        save(EN, en)
        save(NE, ne)
    print(f'added {len(added)} key(s): {", ".join(added) if added else "-"}')
    print(f'en now {len(en)} keys, ne now {len(ne)} keys')
    assert len(en) == len(ne), 'ARB parity broken'


if __name__ == '__main__':
    main()
