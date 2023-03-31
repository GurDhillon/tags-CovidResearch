import psycopg2 as pg
import matplotlib.pyplot as plt
import numpy as np


def get_q1_data(db):
    cur = db.cursor()

    cur.execute("SELECT count(*) "
                "FROM q1;")

    num = cur.fetchone()[0]
    gdp, score = np.zeros(num), np.zeros(num)

    cur.execute("SELECT * "
                "FROM q1 "
                "ORDER BY gdppercapita;")

    i = 0
    for row in cur:
        gdp[i], score[i] = row[1], row[2]
        i += 1

    cur.close()

    return gdp, score


def get_g2_data(db):
    cur = db.cursor()

    cur.execute("SELECT count(*) "
                "FROM q2;")
    num = cur.fetchone()[0]
    gdp, vaccinated = np.zeros(num), np.zeros(num)

    cur.execute("SELECT * "
                "FROM q2 "
                "ORDER BY gdppercapita;")
    i = 0
    for row in cur:
        gdp[i], vaccinated[i] = row[1], row[2]
        i += 1

    cur.close()
    return gdp, vaccinated


def get_q2_extended(db):
    cur = db.cursor()

    cur.execute("SELECT count(*) "
                "FROM WealthyProportion;")
    wealthy_num = cur.fetchone()[0]
    wealthy_dates, wealthy_vaccinated = [], np.zeros(wealthy_num)

    cur.execute("SELECT count(*) "
                "FROM PoorProportion;")
    poor_num = cur.fetchone()[0]
    poor_dates, poor_vaccinated = [], np.zeros(poor_num)

    cur.execute("SELECT count(*) "
                "FROM EUPoorProportion;")
    eu_poor_num = cur.fetchone()[0]
    eu_poor_dates, eu_poor_vaccinated = [], np.zeros(eu_poor_num)

    cur.execute("SELECT * "
                "FROM WealthyProportion "
                "ORDER BY ref_date;")
    i = 0
    for row in cur:
        wealthy_dates.append(row[0])
        wealthy_vaccinated[i] = row[2]
        i += 1

    cur.execute("SELECT * "
                "FROM PoorProportion "
                "ORDER BY ref_date;")
    i = 0
    for row in cur:
        poor_dates.append(row[0])
        poor_vaccinated[i] = row[2]
        i += 1

    cur.execute("SELECT * "
                "FROM EUPoorProportion "
                "ORDER BY ref_date;")
    i = 0
    for row in cur:
        eu_poor_dates.append(row[0])
        eu_poor_vaccinated[i] = row[2]
        i += 1

    return [wealthy_dates, poor_dates, eu_poor_dates], [wealthy_vaccinated, poor_vaccinated, eu_poor_vaccinated]


def get_q3_data(countries, variants, db):
    cur = db.cursor()

    timelines, shares = [], []
    for i in range(len(countries)):
        timeline_group, shares_group = [], []
        for j in range(len(variants)):
            command = f"SELECT count(*) FROM {countries[i] + variants[j]};"
            cur.execute(command)
            num = cur.fetchone()[0]
            timeline, share = [], np.zeros(num)

            command = f"SELECT * FROM {countries[i] + variants[j]} ORDER BY date;"
            cur.execute(command)

            k = 0
            for row in cur:
                timeline.append(row[0])
                share[k] = row[1]
                k += 1

            timeline_group.append(timeline)
            shares_group.append(share)

        timelines.append(timeline_group)
        shares.append(shares_group)

    return timelines, shares


def plot(x, y, marker=None, axis=None, x_label=None, y_label=None, title=None, best_fit=None, filename=None):
    if marker:
        plt.plot(x, y, marker)
    else:
        plt.plot(x, y)

    if best_fit:
        plt.plot(x, best_fit)
    if axis:
        plt.axis(axis)
    if x_label:
        plt.xlabel(x_label)
    if y_label:
        plt.ylabel(y_label)
    if title:
        plt.title(title)
    if filename:
        plt.savefig(filename, dpi=600)

    plt.show()


def plot_multiple(xs, ys, legend, x_label=None, y_label=None, title=None, filename=None):
    for i in range(len(xs)):
        plt.plot(xs[i], ys[i])

    plt.legend(legend)
    plt.grid(True)

    if x_label:
        plt.xlabel(x_label)
    if y_label:
        plt.ylabel(y_label)
    if title:
        plt.title(title)
    if filename:
        plt.savefig(filename, dpi=600)

    plt.show()


def plot_mult_graph(x, y, variants, legend):
    high_dates, high_shares, low_dates, low_shares = x[0], y[0], x[1], y[1]

    plt.figure()
    for i in range(len(variants)):
        plt.subplot(2, 5, i + 1)
        plt.plot(high_dates[i], high_shares[i])
        plt.plot(low_dates[i], low_shares[i])

        #plt.legend(legend)
        plt.xticks([], "")
        plt.yticks([], "")
        plt.title(variants[i])

    plt.show()


def get_r(x, y):
    corr_matrix = np.corrcoef(x, y)
    correlation = corr_matrix[0, 1]
    r_squared = correlation ** 2

    return correlation

def main():
    db = pg.connect(dbname="gurpreet", user="gurpreet", password="", options="-c search_path=phase2")

    gdp, score = get_q1_data(db)
    plot(np.log(gdp), score)

    gdp, vaccinated = get_g2_data(db)
    log_gdp = np.log(gdp)

    print("r for vaccinations: ", get_r(log_gdp, vaccinated))
    best_params = np.polyfit(log_gdp, vaccinated, 1)
    best_y = [datapoint * best_params[0] + best_params[1] for datapoint in log_gdp]
    print("best-fit parameters for vaccinations: ", best_params)

    plot(log_gdp, vaccinated, marker='o', axis=[None, None, None, 1], x_label='Log of GDP Per Capita (USD)',
         y_label='Proportion of Population Fully Vaccinated', title='Country Wealth and Vaccinations', best_fit=best_y,
         filename='vaccinations.jpg')

    dates, vaccinations = get_q2_extended(db)
    plot_multiple(dates, vaccinations, ['Wealthy Countries', 'Impoverished Countries', 'Impoverished EU Member States'],
                  x_label='Date', y_label='Proportion of Population Fully Vaccinated',
                  title='Timeline of vaccinations of wealthy and impoverished countries', filename='comparison.jpg')

    countries = ['High', 'Low']
    variants = ['Beta', 'Epsilon', 'Gamma', 'Kappa', 'Iota', 'Eta', 'Delta', 'Alpha', 'Lambda', 'Mu']

    timelines, shares = get_q3_data(countries, variants, db)
    axes = []
    plot_mult_graph(timelines, shares, variants, ['Wealthy Countries', 'Impoverished Countries'])

    plt.plot(timelines[0][0], shares[0][0])
    plt.plot(timelines[1][0], shares[1][0])
    plt.axis([None, None, -0.002, 0.002])
    plt.show()

    db.close()

if __name__ == '__main__':
    main()
