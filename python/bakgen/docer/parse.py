class ReadStats(object):
    def __init__(self, name1, count1, length1, name2, count2, length2, coverage):
        super(ReadStats, self).__init__()
        self.coverage = coverage
        self.length2 = length2
        self.count2 = count2
        self.name2 = name2
        self.length1 = length1
        self.count1 = count1
        self.name1 = name1

    def __eq__(self, other):
        return self.__dict__ == other.__dict__


class Assembly(object):
    def __init__(self, name, contigs, n50, length, gc, maximum):
        super(Assembly, self).__init__()
        self.maximum = maximum
        self.gc = gc
        self.length = length
        self.n50 = n50
        self.contigs = contigs
        self.name = name

    def __eq__(self, other):
        return self.__dict__ == other.__dict__


class AssemblyStats(object):
    def __init__(self, assemblies):
        super(AssemblyStats, self).__init__()
        self.assemblies = assemblies

    def __eq__(self, other):
        return self.__dict__ == other.__dict__


class Bacterial(object):
    def __init__(self, cds, trna, rrna, tmrna):
        super(Bacterial, self).__init__()
        self.tmrna = tmrna
        self.rrna = rrna
        self.trna = trna
        self.cds = cds

    def __eq__(self, other):
        return self.__dict__ == other.__dict__


def parse_read_stats(lines):
    name1, count1, length1 = map(lambda x: x.replace('\n', ''), lines[0].split('\t'))
    name2, count2, length2 = map(lambda x: x.replace('\n', ''), lines[1].split('\t'))
    coverage = lines[2].split(' ')[-1].replace('\n', '')
    return ReadStats(name1, count1, length1, name2, count2, length2, coverage)


def parse_assembly_stats(lines):
    assemblies = []
    contigs, n50, length, gc, maximum = map(lambda x: x.replace('\n', ''), lines[2].split('\t'))
    assemblies.append(Assembly('spades', contigs, n50, length, gc, maximum))
    contigs, n50, length, gc, maximum = map(lambda x: x.replace('\n', ''), lines[3].split('\t'))
    assemblies.append(Assembly('mira', contigs, n50, length, gc, maximum))
    contigs, n50, length, gc, maximum = map(lambda x: x.replace('\n', ''), lines[4].split('\t'))
    assemblies.append(Assembly('newbler', contigs, n50, length, gc, maximum))
    contigs, n50, length, gc, maximum = map(lambda x: x.replace('\n', ''), lines[5].split('\t'))
    assemblies.append(Assembly('final', contigs, n50, length, gc, maximum))
    return AssemblyStats(assemblies)


def parse_bacterial(lines):
    splitted = dict(map(lambda x: map(lambda y: y.strip().lower(), x.split(':')), lines))
    return Bacterial(splitted.get('cds'), splitted.get('trna'), splitted.get('rrna'),
                     splitted.get('tmrna'))
